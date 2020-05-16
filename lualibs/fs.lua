--portable filesystem API for LuaJIT
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'

-- begin fs/common.lua

local bit = require'bit'

--implement path module to minimize the dependencies (Paul Kulchenko)
local path = {
  sep = package.config:sub(1,1),
  seppat = "[/"..package.config:sub(1,1).."]",
  notseppat = "[^/"..package.config:sub(1,1).."]",
}
path.endsep = function(s) return s:find(path.seppat.."$") ~= nil end
path.combine = function(s1, s2) return path.isabs(s2) and s2 or path.endsep(s1) and s1..s2 or s1..path.sep..s2 end
path.dir = function(s) return s:match("(.+)"..path.seppat..path.notseppat.."+$") end
path.isabs = function(s) return s:find("^"..path.seppat) ~= nil or path.sep == "\\" and s:sub(2,2) == ":" end

local min, max, floor = math.min, math.max, math.floor

local C = ffi.C

local cdef = ffi.cdef
local x64 = ffi.arch == 'x64' or nil
local osx = ffi.os == 'OSX' or nil
local linux = ffi.os == 'Linux' or nil
local win = ffi.abi'win' or nil

--namespaces in which backends can add methods directly.
local fs = {} --fs module namespace
local file = {} --file object methods
local stream = {} --FILE methods

--assert() with string formatting.
local function assert(v, err, ...)
  if v then return v end
  err = err or 'assertion failed!'
  if select('#',...) > 0 then
    err = string.format(err,...)
  end
  error(err, 2)
end

--return a function which reuses and returns an ever-increasing buffer.
local function mkbuf(ctype, min_sz)
  ctype = ffi.typeof('$[?]', ffi.typeof(ctype))
  min_sz = min_sz or 256
  assert(min_sz > 0)
  local buf, bufsz
  return function(sz)
    sz = sz or bufsz or min_sz
    assert(sz > 0)
    if not bufsz or sz > bufsz then
      buf, bufsz = ctype(sz), sz
    end
    return buf, bufsz
  end
end

--error reporting ------------------------------------------------------------

cdef'char *strerror(int errnum);'

local error_classes = {
  [2] = 'not_found', --ENOENT, _open_osfhandle(), _fdopen(), open(), mkdir(),
  --rmdir(), opendir(), rename(), unlink()
  [5] = 'io_error', --EIO, readlink()
  [17] = 'already_exists', --EEXIST, open(), mkdir()
  [20] = 'not_found', --ENOTDIR, opendir()
  --[21] = 'access_denied', --EISDIR, unlink()
  [linux and 39 or osx and 66 or ''] = 'not_empty',
  --ENOTEMPTY, rmdir()
  [28] = 'disk_full', --ENOSPC: fallocate()
  [linux and 95 or ''] = 'not_supported', --EOPNOTSUPP: fallocate()

  --[[ --TODO: mmap
	local ENOENT = 2
	local ENOMEM = 12
	local EINVAL = 22
	local EFBIG  = 27
	local ENOSPC = 28
	local EDQUOT = osx and 69 or 122

	local errcodes = {
		[ENOENT] = 'not_found',
		[ENOMEM] = 'out_of_mem',
		[EINVAL] = 'file_too_short',
		[EFBIG] = 'disk_full',
		[ENOSPC] = 'disk_full',
		[EDQUOT] = 'disk_full',
	}
	]]

  --[[
	[12] = 'out_of_mem', --TODO: ENOMEM: mmap
	[22] = 'file_too_short', --TODO: EINVAL: mmap
	[27] = 'disk_full', --TODO: EFBIG
	[osx and 69 or 122] = 'disk_full', --TODO: EDQUOT
	]]
}

local function check_errno(ret, errno)
  if ret then return ret end
  errno = errno or ffi.errno()
  local err = error_classes[errno]
  if not err then
    local s = C.strerror(errno)
    err = s ~= nil and ffi.string(s) or 'Error '..errno
  end
  return ret, err, errno
end

--flags arg parsing ----------------------------------------------------------

--turn a table of boolean options into a bit mask.
local function table_flags(t, masks, strict)
  local bits = 0
  local mask = 0
  for k,v in pairs(t) do
    local flag
    if type(k) == 'string' and v then --flags as table keys: {flag->true}
      flag = k
    elseif type(k) == 'number'
    and floor(k) == k
    and type(v) == 'string'
    then --flags as array: {flag1,...}
      flag = v
    end
    local bitmask = masks[flag]
    if strict then
      assert(bitmask, 'invalid flag: "%s"', tostring(flag))
    elseif bitmask then
      mask = bit.bor(mask, bitmask)
      if flag then
        bits = bit.bor(bits, bitmask)
      end
    end
  end
  return bits, mask
end

--turn 'opt1 +opt2 -opt3' -> {opt1=true, opt2=true, opt3=false}
local function string_flags(s, masks, strict)
  local t = {}
  for s in s:gmatch'[^ ,]+' do
    local m,s = s:match'^([%+%-]?)(.*)$'
    t[s] = m ~= '-'
  end
  return table_flags(t, masks, strict)
end

--set one or more bits of a value without affecting other bits.
local function setbits(bits, mask, over)
  return over and bit.bor(bits, bit.band(over, bit.bnot(mask))) or bits
end

--cache tuple(options_string, masks_table) -> bits, mask
local cache = {}
local function getcache(s, masks)
  cache[masks] = cache[masks] or {}
  local t = cache[masks][s]
  if not t then return end
  return t[1], t[2]
end
local function setcache(s, masks, bits, mask)
  cache[masks][s] = {bits, mask}
end

local function flags(arg, masks, cur_bits, strict)
  if type(arg) == 'string' then
    local bits, mask = getcache(arg, masks)
    if not bits then
      bits, mask = string_flags(arg, masks, strict)
      setcache(arg, masks, bits, mask)
    end
    return setbits(bits, mask, cur_bits)
  elseif type(arg) == 'table' then
    local bits, mask = table_flags(arg, masks, strict)
    return setbits(bits, mask, cur_bits)
  elseif type(arg) == 'number' then
    return arg
  elseif arg == nil then
    return 0
  else
    assert(false, 'flags expected but "%s" given', type(arg))
  end
end

--file objects ---------------------------------------------------------------

--returns a read(buf, sz) -> sz function which reads ahead from file
function file.buffered_read(f, ctype, bufsize)
  local elem_ct = ffi.typeof(ctype or 'char')
  local ptr_ct = ffi.typeof('$*', elem_ct)
  assert(ffi.sizeof(elem_ct) == 1)
  local buf_ct = ffi.typeof('$[?]', elem_ct)
  local bufsize = bufsize or 4096
  local buf = buf_ct(bufsize)
  local ofs, len = 0, 0
  local eof = false
  return function(dst, sz)
    if not dst then --skip bytes (libjpeg semantics)
      local pos0, err, errcode = f:seek'cur'
      if not pos0 then return nil, err, errcode end
      local pos, err, errcode = f:seek('cur', sz)
      if not pos then return nil, err, errcode end
      return pos - pos0
    end
    local rsz = 0
    while sz > 0 do
      if len == 0 then
        if eof then
          return 0
        end
        ofs = 0
        local len1, err, errcode = f:read(buf, bufsize)
        if not len1 then return nil, err, errcode end
        len = len1
        if len == 0 then
          eof = true
          return rsz
        end
      end
      local n = min(sz, len)
      ffi.copy(ffi.cast(ptr_ct, dst) + rsz, buf + ofs, n)
      ofs = ofs + n
      len = len - n
      rsz = rsz + n
      sz = sz - n
    end
    return rsz
  end
end

--stdio streams --------------------------------------------------------------

cdef[[
typedef struct FILE FILE;
int fclose(FILE*);
]]

local stream_ct = ffi.typeof'struct FILE'

function stream.close(fs)
  local ok = C.fclose(fs) == 0
  if not ok then return check_errno() end
  ffi.gc(fs, nil)
  return true
end

--i/o ------------------------------------------------------------------------

local whences = {set = 0, cur = 1, ['end'] = 2} --FILE_*
function file.seek(f, whence, offset)
  if tonumber(whence) and not offset then --middle arg missing
    whence, offset = 'cur', tonumber(whence)
  end
  whence = whence or 'cur'
  offset = tonumber(offset or 0)
  whence = assert(whences[whence], 'invalid whence: "%s"', whence)
  return f._seek(f, whence, offset)
end

-- end fs/common.lua

if win then

--types, consts, utils -------------------------------------------------------

  if x64 then
    cdef'typedef int64_t ULONG_PTR;'
  else
    cdef'typedef int32_t ULONG_PTR;'
  end

  cdef[[
typedef void           VOID, *PVOID, *LPVOID;
typedef VOID*          HANDLE;
typedef unsigned short WORD;
typedef unsigned long  DWORD, *PDWORD, *LPDWORD;
typedef unsigned int   UINT;
typedef int            BOOL;
typedef ULONG_PTR      SIZE_T;
typedef const void*    LPCVOID;
typedef char*          LPSTR;
typedef const char*    LPCSTR;
typedef wchar_t        WCHAR;
typedef WCHAR*         LPWSTR;
typedef const WCHAR*   LPCWSTR;
typedef BOOL           *LPBOOL;
typedef void*          HMODULE;
typedef unsigned char  UCHAR;
typedef unsigned short USHORT;
typedef long           LONG;
typedef unsigned long  ULONG;
typedef long long      LONGLONG;

typedef union {
	struct {
		DWORD LowPart;
		LONG HighPart;
	};
	struct {
		DWORD LowPart;
		LONG HighPart;
	} u;
	LONGLONG QuadPart;
} LARGE_INTEGER, *PLARGE_INTEGER;

typedef struct {
	DWORD  nLength;
	LPVOID lpSecurityDescriptor;
	BOOL   bInheritHandle;
} SECURITY_ATTRIBUTES, *LPSECURITY_ATTRIBUTES;
]]

  local INVALID_HANDLE_VALUE = ffi.cast('HANDLE', -1)

  local wbuf = mkbuf'WCHAR'
  local libuf = ffi.new'LARGE_INTEGER[1]'

--error reporting ------------------------------------------------------------

  cdef[[
DWORD GetLastError(void);

DWORD FormatMessageA(
	DWORD dwFlags,
	LPCVOID lpSource,
	DWORD dwMessageId,
	DWORD dwLanguageId,
	LPSTR lpBuffer,
	DWORD nSize,
	va_list *Arguments
);
]]

  local FORMAT_MESSAGE_FROM_SYSTEM = 0x00001000

  local errbuf = mkbuf'char'

  local error_classes = {
    [0x002] = 'File not found', --ERROR_FILE_NOT_FOUND, CreateFileW
    [0x003] = 'Path not found', --ERROR_PATH_NOT_FOUND, CreateDirectoryW
    [0x005] = 'Access denied', --ERROR_ACCESS_DENIED, CreateFileW
    [0x050] = 'File exists', --ERROR_FILE_EXISTS, CreateFileW
    [0x091] = 'Directory not empty', --ERROR_DIR_NOT_EMPTY, RemoveDirectoryW
    [0x0b7] = 'Already exists', --ERROR_ALREADY_EXISTS, CreateDirectoryW
    [0x10B] = 'Directory not found', --ERROR_DIRECTORY, FindFirstFileW

    --TODO: mmap
    [0x0008] = 'File too short', --readonly file too short
    [0x0057] = 'Out of mem', --size or address too large
    [0x0070] = 'Sisk full',
    [0x01E7] = 'Address in use', --address in use
    [0x03ee] = 'File too short', --file has zero size
    [0x05af] = 'Out of mem', --swapfile too short

  }

  local function check(ret, errcode)
    if ret then return ret end
    errcode = errcode or C.GetLastError()
    local buf, bufsz = errbuf(256)
    local sz = C.FormatMessageA(
      FORMAT_MESSAGE_FROM_SYSTEM, nil, errcode, 0, buf, bufsz, nil)
    local err =
    error_classes[errcode]
    or (sz > 0
      and ffi.string(buf, sz):gsub('[\r\n]+$', '')
      or 'Error '..errcode)
    return ret, err, errcode
  end

--utf16/utf8 conversion ------------------------------------------------------

  cdef[[
int MultiByteToWideChar(
	UINT     CodePage,
	DWORD    dwFlags,
	LPCSTR   lpMultiByteStr,
	int      cbMultiByte,
	LPWSTR   lpWideCharStr,
	int      cchWideChar
);
int WideCharToMultiByte(
	UINT     CodePage,
	DWORD    dwFlags,
	LPCWSTR  lpWideCharStr,
	int      cchWideChar,
	LPSTR    lpMultiByteStr,
	int      cbMultiByte,
	LPCSTR   lpDefaultChar,
	LPBOOL   lpUsedDefaultChar
);
]]

  local CP_UTF8 = 65001

  local wcsbuf = mkbuf'WCHAR'

  local function wcs(s, msz, wbuf) --string -> WCHAR[?]
    msz = msz and msz + 1 or #s + 1
    wbuf = wbuf or wcsbuf
    local wsz = C.MultiByteToWideChar(CP_UTF8, 0, s, msz, nil, 0)
    assert(wsz > 0) --should never happen otherwise
    local buf = wbuf(wsz)
    local sz = C.MultiByteToWideChar(CP_UTF8, 0, s, msz, buf, wsz)
    assert(sz == wsz) --should never happen otherwise
    return buf
  end

--open/close -----------------------------------------------------------------

  cdef[[
HANDLE CreateFileW(
	LPCWSTR lpFileName,
	DWORD dwDesiredAccess,
	DWORD dwShareMode,
	LPSECURITY_ATTRIBUTES lpSecurityAttributes,
	DWORD dwCreationDisposition,
	DWORD dwFlagsAndAttributes,
	HANDLE hTemplateFile
);
BOOL CloseHandle(HANDLE hObject);
]]

--CreateFile access rights flags
  local t = {
    --FILE_* (specific access rights)
    list_directory           = 1, --dirs:  allow listing
    read_data                = 1, --files: allow reading data
    add_file                 = 2, --dirs:  allow creating files
    write_data               = 2, --files: allow writting data
    add_subdirectory         = 4, --dirs:  allow creating subdirs
    append_data              = 4, --files: allow appending data
    create_pipe_instance     = 4, --pipes: allow creating a pipe
    delete_child          = 0x40, --dirs:  allow deleting dir contents
    traverse              = 0x20, --dirs:  allow traversing (not effective)
    execute               = 0x20, --exes:  allow exec'ing
    read_attributes       = 0x80, --allow reading attrs
    write_attributes     = 0x100, --allow setting attrs
    read_ea                  = 8, --allow reading extended attrs
    write_ea              = 0x10, --allow writting extended attrs
    --object's standard access rights
    delete       = 0x00010000,
    read_control = 0x00020000, --allow r/w the security descriptor
    write_dac    = 0x00040000,
    write_owner  = 0x00080000,
    synchronize  = 0x00100000,
    --STANDARD_RIGHTS_*
    standard_rights_required = 0x000F0000,
    standard_rights_read     = 0x00020000, --read_control
    standard_rights_write    = 0x00020000, --read_control
    standard_rights_execute  = 0x00020000, --read_control
    standard_rights_all      = 0x001F0000,
    --GENERIC_*
    generic_read    = 0x80000000,
    generic_write   = 0x40000000,
    generic_execute = 0x20000000,
    generic_all     = 0x10000000,
  }
--FILE_ALL_ACCESS
  t.all_access = bit.bor(
    t.standard_rights_required,
    t.synchronize,
    0x1ff)
--FILE_GENERIC_*
  t.read = bit.bor(
    t.standard_rights_read,
    t.read_data,
    t.read_attributes,
    t.read_ea,
    t.synchronize)
  t.write = bit.bor(
    t.standard_rights_write,
    t.write_data,
    t.write_attributes,
    t.write_ea,
    t.append_data,
    t.synchronize)
  t.execute = bit.bor(
    t.standard_rights_execute,
    t.read_attributes,
    t.execute,
    t.synchronize)
  local access_bits = t

--CreateFile sharing flags
  local sharing_bits = {
    --FILE_SHARE_*
    read   = 0x00000001, --allow us/others to read
    write  = 0x00000002, --allow us/others to write
    delete = 0x00000004, --allow us/others to delete or rename
  }

--CreateFile creation disposition flags
  local creation_bits = {
    create_new        = 1, --create or fail
    create_always     = 2, --open or create + truncate
    open_existing     = 3, --open or fail
    open_always       = 4, --open or create
    truncate_existing = 5, --open + truncate or fail
  }

  local FILE_ATTRIBUTE_NORMAL = 0x00000080 --for when no bits are set

--CreateFile flags & attributes
  local attr_bits = {
    --FILE_ATTRIBUTE_*
    readonly      = 0x00000001,
    hidden        = 0x00000002,
    system        = 0x00000004,
    archive       = 0x00000020,
    temporary     = 0x00000100,
    sparse_file   = 0x00000200,
    reparse_point = 0x00000400,
    compressed    = 0x00000800,
    directory     = 0x00000010,
    device        = 0x00000040,
    --offline     = 0x00001000, --reserved (used by Remote Storage)
    not_indexed   = 0x00002000, --FILE_ATTRIBUTE_NOT_CONTENT_INDEXED
    encrypted     = 0x00004000,
    --virtual     = 0x00010000, --reserved
  }

  local flag_bits = {
    --FILE_FLAG_*
    write_through        = 0x80000000,
    overlapped           = 0x40000000,
    no_buffering         = 0x20000000,
    random_access        = 0x10000000,
    sequential_scan      = 0x08000000,
    delete_on_close      = 0x04000000,
    backup_semantics     = 0x02000000,
    posix_semantics      = 0x01000000,
    open_reparse_point   = 0x00200000,
    open_no_recall       = 0x00100000,
    first_pipe_instance  = 0x00080000,
  }

  local str_opt = {
    r = {
      access = 'read',
      creation = 'open_existing',
      flags = 'backup_semantics'},
    w = {
      access = 'write file_read_attributes',
      creation = 'create_always',
      flags = 'backup_semantics'},
    ['r+'] = {
      access = 'read write',
      creation = 'open_existing',
      flags = 'backup_semantics'},
    ['w+'] = {
      access = 'read write',
      creation = 'create_always',
      flags = 'backup_semantics'},
  }

  --expose this because the frontend will set its metatype at the end.
  local file_ct = ffi.typeof[[
	struct {
		HANDLE handle;
	}
]]

  function fs.open(path, opt)
    opt = opt or 'r'
    if type(opt) == 'string' then
      opt = assert(str_opt[opt], 'invalid option %s', opt)
    end
    local access   = flags(opt.access or 'read', access_bits)
    local sharing  = flags(opt.sharing or 'read', sharing_bits)
    local creation = flags(opt.creation or 'open_existing', creation_bits)
    local attrbits = flags(opt.attrs, attr_bits)
    attrbits = attrbits == 0 and FILE_ATTRIBUTE_NORMAL or attrbits
    local flagbits = flags(opt.flags, flag_bits)
    local attflags = bit.bor(attrbits, flagbits)
    local h = C.CreateFileW(
      wcs(path), access, sharing, nil, creation, attflags, nil)
    if h == INVALID_HANDLE_VALUE then return check() end
    return ffi.gc(file_ct(h), file.close)
  end

  function file.closed(f)
    return f.handle == INVALID_HANDLE_VALUE
  end

  function file.close(f)
    if f:closed() then return end
    local ret = C.CloseHandle(f.handle)
    if ret == 0 then return check(false) end
    f.handle = INVALID_HANDLE_VALUE
    ffi.gc(f, nil)
    return true
  end

  function fs.wrap_handle(h)
    return file_ct(h)
  end

  cdef[[
int _fileno(struct FILE *stream);
HANDLE _get_osfhandle(int fd);
]]

  function fs.wrap_fd(fd)
    local h = C._get_osfhandle(fd)
    if h == nil then return check_errno() end
    return fs.wrap_handle(h)
  end

  function fs.fileno(file)
    local fd = C._fileno(file)
    return check_errno(fd ~= -1 and fd or nil)
  end

  function fs.wrap_file(file)
    local fd, err, errno = fs.fileno(file)
    if not fd then return nil, err, errno end
    return fs.wrap_fd(fd)
  end

-- the following definitions are borrowed with few tweaks from
-- https://github.com/malkia/luajit-winapi/blob/master/ffi/winapi/windows/shell32.lua

  cdef[[
typedef unsigned char BYTE;
# pragma pack( push, 1 )
  typedef struct SHITEMID {
    USHORT cb;
    BYTE abID[1];
  } SHITEMID;
# pragma pack( pop )
# pragma pack( push, 1 )
  typedef struct ITEMIDLIST {
    SHITEMID mkid;
  } ITEMIDLIST;
# pragma pack( pop )
typedef ITEMIDLIST *PIDLIST_ABSOLUTE; //Pointer
typedef ITEMIDLIST *PCIDLIST_ABSOLUTE; //Pointer
typedef ITEMIDLIST *PIDLIST_RELATIVE; //Pointer
typedef ITEMIDLIST *PCUITEMID_CHILD; //Pointer
typedef PCUITEMID_CHILD *PCUITEMID_CHILD_ARRAY; //Pointer
typedef int32_t HRESULT; //Integer

HRESULT SHOpenFolderAndSelectItems(
  PCIDLIST_ABSOLUTE pidlFolder, UINT cidl, PCUITEMID_CHILD_ARRAY* apidl, DWORD dwFlags);
PIDLIST_ABSOLUTE ILCreateFromPath(LPCWSTR pszPath);
void ILFree(PIDLIST_RELATIVE pidl);
]]

  function fs.shell_open_and_select(path)
    local shell = ffi.load('Shell32.dll')
    local pidl = shell.ILCreateFromPath(wcs(path))
    if pidl then
      shell.SHOpenFolderAndSelectItems(pidl, 0, nil, 0)
      shell.ILFree(pidl)
    end
  end

  cdef[[
void OutputDebugStringW(LPCWSTR lpOutputString);
]]

  function fs.output_debug_string(str)
    local kernel = ffi.load('Kernel32.dll')
    kernel.OutputDebugStringW(wcs(str))
  end

--stdio streams --------------------------------------------------------------

  cdef[[
FILE *_fdopen(int fd, const char *mode);
int _open_osfhandle (HANDLE osfhandle, int flags);
]]

  function file.stream(f, mode)
    local flags = 0
    local fd = C._open_osfhandle(f.handle, flags)
    if fd == -1 then return check_errno() end
    local fs = C._fdopen(fd, mode)
    if fs == nil then return check_errno() end
    ffi.gc(f, nil) --fclose() will close the handle
    ffi.gc(fs, stream.close)
    return fs
  end

--i/o ------------------------------------------------------------------------

  cdef[[
typedef struct _OVERLAPPED {
	ULONG_PTR Internal;
	ULONG_PTR InternalHigh;
	union {
		struct {
			DWORD Offset;
			DWORD OffsetHigh;
		};
	  PVOID Pointer;
	};
	HANDLE hEvent;
} OVERLAPPED, *LPOVERLAPPED;

typedef struct _OVERLAPPED_ENTRY {
	ULONG_PTR    lpCompletionKey;
	LPOVERLAPPED lpOverlapped;
	ULONG_PTR    Internal;
	DWORD        dwNumberOfBytesTransferred;
} OVERLAPPED_ENTRY, *LPOVERLAPPED_ENTRY;

BOOL ReadFile(
	HANDLE       hFile,
	LPVOID       lpBuffer,
	DWORD        nNumberOfBytesToRead,
	LPDWORD      lpNumberOfBytesRead,
	LPOVERLAPPED lpOverlapped
);

BOOL WriteFile(
	HANDLE       hFile,
	LPCVOID      lpBuffer,
	DWORD        nNumberOfBytesToWrite,
	LPDWORD      lpNumberOfBytesWritten,
	LPOVERLAPPED lpOverlapped
);

BOOL FlushFileBuffers(HANDLE hFile);

BOOL SetFilePointerEx(
	HANDLE         hFile,
	LARGE_INTEGER  liDistanceToMove,
	PLARGE_INTEGER lpNewFilePointer,
	DWORD          dwMoveMethod
);
]]

  local dwbuf = ffi.new'DWORD[1]'

  function file.read(f, buf, sz)
    local ok = C.ReadFile(f.handle, buf, sz, dwbuf, nil) ~= 0
    if not ok then return check() end
    return dwbuf[0]
  end

  function file.write(f, buf, sz)
    local ok = C.WriteFile(f.handle, buf, sz or #buf, dwbuf, nil) ~= 0
    if not ok then return check() end
    return dwbuf[0]
  end

  function file.flush(f)
    return check(C.FlushFileBuffers(f.handle) ~= 0)
  end

  local ofsbuf = ffi.new'LARGE_INTEGER[1]'
  function file._seek(f, whence, offset)
    ofsbuf[0].QuadPart = offset
    local ok = C.SetFilePointerEx(f.handle, ofsbuf[0], libuf, whence) ~= 0
    if not ok then return check() end
    return tonumber(libuf[0].QuadPart)
  end

--truncate/getsize/setsize ---------------------------------------------------

  cdef[[
BOOL SetEndOfFile(HANDLE hFile);
BOOL GetFileSizeEx(HANDLE hFile, PLARGE_INTEGER lpFileSize);
]]

--NOTE: seeking beyond file size and then truncating the file incurs no delay
--on NTFS, but that's not because the file becomes sparse (it doesn't, and
--disk space _is_ reserved), but because the extra zero bytes are not written
--until the first write call _that requires it_. This is a good optimization
--since usually the file will be written sequentially after the truncation
--in which case those extra zero bytes will never get a chance to be written.
  function file.truncate(f, opt)
    return check(C.SetEndOfFile(f.handle) ~= 0)
  end

  function file_getsize(f)
    local ok = C.GetFileSizeEx(f.handle, libuf) ~= 0
    if not ok then return check() end
    return tonumber(libuf[0].QuadPart)
  end

--filesystem operations ------------------------------------------------------

  cdef[[
BOOL CreateDirectoryW(LPCWSTR, LPSECURITY_ATTRIBUTES);
BOOL RemoveDirectoryW(LPCWSTR);
int SetCurrentDirectoryW(LPCWSTR lpPathName);
DWORD GetCurrentDirectoryW(DWORD nBufferLength, LPWSTR lpBuffer);
BOOL DeleteFileW(LPCWSTR lpFileName);
BOOL MoveFileExW(
	LPCWSTR lpExistingFileName,
	LPCWSTR lpNewFileName,
	DWORD   dwFlags
);
]]

  local move_bits = {
    --MOVEFILE_*
    replace_existing      =  0x1,
    copy_allowed          =  0x2,
    delay_until_reboot    =  0x4,
    fail_if_not_trackable = 0x20,
    write_through         =  0x8, --for when copy_allowed
  }

--TODO: MoveFileExW is actually NOT atomic.
--Use SetFileInformationByHandle with FILE_RENAME_INFO and ReplaceIfExists
--which is atomic and also works on open handles which is even more atomic :)
  local default_move_opt = 'replace_existing write_through' --posix
  function fs.move(oldpath, newpath, opt)
    return check(C.MoveFileExW(
        wcs(oldpath),
        wcs(newpath, nil, wbuf),
        flags(opt or default_move_opt, move_bits)
        ) ~= 0)
  end

--symlinks & hardlinks -------------------------------------------------------

  cdef[[
BOOL CreateSymbolicLinkW (
	LPCWSTR lpSymlinkFileName,
	LPCWSTR lpTargetFileName,
	DWORD dwFlags
);
BOOL CreateHardLinkW(
	LPCWSTR lpFileName,
	LPCWSTR lpExistingFileName,
	LPSECURITY_ATTRIBUTES lpSecurityAttributes
);

BOOL DeviceIoControl(
	HANDLE       hDevice,
	DWORD        dwIoControlCode,
	LPVOID       lpInBuffer,
	DWORD        nInBufferSize,
	LPVOID       lpOutBuffer,
	DWORD        nOutBufferSize,
	LPDWORD      lpBytesReturned,
	LPOVERLAPPED lpOverlapped
);
]]

  local SYMBOLIC_LINK_FLAG_DIRECTORY = 0x1

  function fs.mksymlink(link_path, target_path, is_dir)
    local flags = is_dir and SYMBOLIC_LINK_FLAG_DIRECTORY or 0
    return check(C.CreateSymbolicLinkW(
        wcs(link_path),
        wcs(target_path, nil, wbuf),
        flags) ~= 0)
  end

  function fs.mkhardlink(link_path, target_path)
    return check(C.CreateHardLinkW(
        wcs(link_path),
        wcs(target_path, nil, wbuf),
        nil) ~= 0)
  end

  cdef[[
DWORD GetFileAttributesW (
    LPCWSTR lpFileName
);
]]

  local INVALID_FILE_ATTRIBUTES = 0xFFFFFFFF
  local FILE_ATTRIBUTE_REPARSE_POINT = 0x400

  function fs.is_symlink(path)
    if not path then return nil end
    local flags = C.GetFileAttributesW(wcs(path))
    if flags == INVALID_FILE_ATTRIBUTES then return false end
    return bit.band(flags, FILE_ATTRIBUTE_REPARSE_POINT) == FILE_ATTRIBUTE_REPARSE_POINT
  end

  ffi.metatype(file_ct, {__index = file})
  ffi.metatype(stream_ct, {__index = stream})

else
  error('platform not Windows')
end

return fs
