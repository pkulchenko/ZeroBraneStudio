#!/bin/bash

case "$(uname -m)" in
	x86_64)
		FPIC="-fpic"
		ARCH="x64"
		;;
	armv7l)
		FPIC="-fpic"
		ARCH="armhf"
		;;
	*)
		FPIC=""
		ARCH="x86"
		;;
esac

# ZBS binary directory
BIN_DIR="$(dirname "$PWD")/bin/linux/$ARCH"

# temporary installation directory for dependencies
INSTALL_DIR="$PWD/deps"

# number of parallel jobs used for building
MAKEFLAGS="-j4"

# flags for manual building with gcc
BUILD_FLAGS="-O2 -shared -s -I $INSTALL_DIR/include -L $INSTALL_DIR/lib $FPIC"

# paths configuration
WXWIDGETS_BASENAME="wxWidgets"
WXWIDGETS_URL="https://github.com/pkulchenko/wxWidgets.git"

WXLUA_BASENAME="wxlua"
WXLUA_URL="https://svn.code.sf.net/p/wxlua/svn/trunk"

LUASOCKET_BASENAME="luasocket-3.0-rc1"
LUASOCKET_FILENAME="v3.0-rc1.zip"
LUASOCKET_URL="https://github.com/diegonehab/luasocket/archive/$LUASOCKET_FILENAME"

# exit if the command line is empty
if [ $# -eq 0 ]; then
  echo "Usage: $0 LIBRARY..."
  exit 0
fi

WXLUASTRIP="/strip"
WXWIDGETSDEBUG="--disable-debug"
WXLUABUILD="MinSizeRel"

# iterate through the command line arguments
for ARG in "$@"; do
  case $ARG in
  5.2)
    BUILD_52=true
    ;;
  5.3)
    BUILD_53=true
    BUILD_FLAGS="$BUILD_FLAGS -DLUA_COMPAT_APIINTCASTS"
    ;;
  jit)
    BUILD_JIT=true
    ;;
  wxwidgets)
    BUILD_WXWIDGETS=true
    ;;
  lua)
    BUILD_LUA=true
    ;;
  wxlua)
    BUILD_WXLUA=true
    ;;
  luasocket)
    BUILD_LUASOCKET=true
    ;;
  debug)
    WXLUASTRIP=""
    WXWIDGETSDEBUG="--enable-debug=max --enable-debug_gdb"
    WXLUABUILD="Debug"
    ;;
  all)
    BUILD_WXWIDGETS=true
    BUILD_LUA=true
    BUILD_WXLUA=true
    BUILD_LUASOCKET=true
    ;;
  *)
    echo "Error: invalid argument $ARG"
    exit 1
    ;;
  esac
done

# check for g++
if [ ! "$(which g++)" ]; then
  echo "Error: g++ isn't found. Please install GNU C++ compiler."
  exit 1
fi

# check for cmake
if [ ! "$(which cmake)" ]; then
  echo "Error: cmake isn't found. Please install CMake and add it to PATH."
  exit 1
fi

# check for svn
if [ ! "$(which svn)" ]; then
  echo "Error: svn isn't found. Please install console SVN client."
  exit 1
fi

# check for wget
if [ ! "$(which wget)" ]; then
  echo "Error: wget isn't found. Please install GNU Wget."
  exit 1
fi

# create the installation directory
mkdir -p "$INSTALL_DIR" || { echo "Error: cannot create directory $INSTALL_DIR"; exit 1; }

LUAV="51"
LUAS=""
LUA_BASENAME="lua-5.1.5"

if [ $BUILD_52 ]; then
  LUAV="52"
  LUAS=$LUAV
  LUA_BASENAME="lua-5.2.4"
fi

LUA_FILENAME="$LUA_BASENAME.tar.gz"
LUA_URL="http://www.lua.org/ftp/$LUA_FILENAME"

if [ $BUILD_53 ]; then
  LUAV="53"
  LUAS=$LUAV
  LUA_BASENAME="lua-5.3.1"
  LUA_FILENAME="$LUA_BASENAME.tar.gz"
  LUA_URL="http://www.lua.org/ftp/$LUA_FILENAME"
fi

if [ $BUILD_JIT ]; then
  LUA_BASENAME="LuaJIT-2.0.4"
  LUA_FILENAME="$LUA_BASENAME.tar.gz"
  LUA_URL="http://luajit.org/download/$LUA_FILENAME"
fi

# build wxWidgets
if [ $BUILD_WXWIDGETS ]; then
  git clone "$WXWIDGETS_URL" "$WXWIDGETS_BASENAME" || { echo "Error: failed to get wxWidgets"; exit 1; }

  cd "$WXWIDGETS_BASENAME"
  ./configure --prefix="$INSTALL_DIR" $WXWIDGETSDEBUG --disable-shared --enable-unicode \
    --enable-compat28 \
    --with-libjpeg=builtin --with-libpng=builtin --with-libtiff=no --with-expat=no \
    --with-zlib=builtin --disable-richtext --with-gtk=2 \
    CFLAGS="-Os -fPIC" CXXFLAGS="-Os -fPIC"
  make $MAKEFLAGS || { echo "Error: failed to build wxWidgets"; exit 1; }
  make install
  cd ..
  rm -rf "$WXWIDGETS_BASENAME"
fi

# build Lua
if [ $BUILD_LUA ]; then
  wget -c "$LUA_URL" -O "$LUA_FILENAME" || { echo "Error: failed to download Lua"; exit 1; }
  tar -xzf "$LUA_FILENAME"
  cd "$LUA_BASENAME"

  if [ $BUILD_JIT ]; then
    make CCOPT="-DLUAJIT_ENABLE_LUA52COMPAT" || { echo "Error: failed to build Lua"; exit 1; }
    make install PREFIX="$INSTALL_DIR"
    cp "$INSTALL_DIR/bin/luajit" "$INSTALL_DIR/bin/lua"
    # move luajit to lua as it's expected by luasocket and other components
    cp "$INSTALL_DIR"/include/luajit*/* "$INSTALL_DIR/include/"
  else
    # use POSIX as it has minimum dependencies (no readline and no ncurses required)
    # LUA_USE_DLOPEN is required for loading libraries
    (cd src; make all MYCFLAGS="$FPIC -DLUA_USE_POSIX -DLUA_USE_DLOPEN" MYLIBS="-Wl,-E -ldl") || { echo "Error: failed to build Lua"; exit 1; }
    make install INSTALL_TOP="$INSTALL_DIR"
  fi
  cp "$INSTALL_DIR/bin/lua" "$INSTALL_DIR/bin/lua$LUAV"

  cd ..
  rm -rf "$LUA_FILENAME" "$LUA_BASENAME"
fi

# build wxLua
if [ $BUILD_WXLUA ]; then
  svn co "$WXLUA_URL" "$WXLUA_BASENAME" || { echo "Error: failed to checkout wxLua"; exit 1; }
  cd "$WXLUA_BASENAME/wxLua"
  # the following patches wxlua source to fix live coding support in wxlua apps
  # http://www.mail-archive.com/wxlua-users@lists.sourceforge.net/msg03225.html
  sed -i 's/\(m_wxlState = wxLuaState(wxlState.GetLuaState(), wxLUASTATE_GETSTATE|wxLUASTATE_ROOTSTATE);\)/\/\/ removed by ZBS build process \/\/ \1/' modules/wxlua/wxlcallb.cpp

  # remove "Unable to call an unknown method..." error as it leads to a leak
  # see http://sourceforge.net/p/wxlua/mailman/message/34629522/ for details
  sed -i '/Unable to call an unknown method/{N;s/.*/    \/\/ removed by ZBS build process/}' modules/wxlua/wxlbind.cpp

  cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" -DCMAKE_BUILD_TYPE=$WXLUABUILD -DBUILD_SHARED_LIBS=FALSE \
    -DwxWidgets_CONFIG_EXECUTABLE="$INSTALL_DIR/bin/wx-config" \
    -DwxWidgets_COMPONENTS="stc;html;aui;adv;core;net;base" \
    -DwxLuaBind_COMPONENTS="stc;html;aui;adv;core;net;base" -DwxLua_LUA_LIBRARY_USE_BUILTIN=FALSE \
    -DwxLua_LUA_INCLUDE_DIR="$INSTALL_DIR/include" -DwxLua_LUA_LIBRARY="$INSTALL_DIR/lib/liblua.a" .
  (cd modules/luamodule; make $MAKEFLAGS) || { echo "Error: failed to build wxLua"; exit 1; }
  (cd modules/luamodule; make install$WXLUASTRIP)
  [ -f "$INSTALL_DIR/lib/libwx.so" ] || { echo "Error: libwx.so isn't found"; exit 1; }
  cd ../..
  rm -rf "$WXLUA_BASENAME"
fi

# build LuaSocket
if [ $BUILD_LUASOCKET ]; then
  wget --no-check-certificate -c "$LUASOCKET_URL" -O "$LUASOCKET_FILENAME" || { echo "Error: failed to download LuaSocket"; exit 1; }
  unzip "$LUASOCKET_FILENAME"
  cd "$LUASOCKET_BASENAME"
  mkdir -p "$INSTALL_DIR/lib/lua/$LUAV/"{mime,socket}
  gcc $BUILD_FLAGS -o "$INSTALL_DIR/lib/lua/$LUAV/mime/core.so" src/mime.c -llua \
    || { echo "Error: failed to build LuaSocket"; exit 1; }
  gcc $BUILD_FLAGS -o "$INSTALL_DIR/lib/lua/$LUAV/socket/core.so" \
    src/{auxiliar.c,buffer.c,except.c,inet.c,io.c,luasocket.c,options.c,select.c,tcp.c,timeout.c,udp.c,usocket.c} -llua \
    || { echo "Error: failed to build LuaSocket"; exit 1; }
  mkdir -p "$INSTALL_DIR/share/lua/$LUAV/socket"
  cp src/{ftp.lua,http.lua,smtp.lua,tp.lua,url.lua} "$INSTALL_DIR/share/lua/$LUAV/socket"
  cp src/{ltn12.lua,mime.lua,socket.lua} "$INSTALL_DIR/share/lua/$LUAV"
  [ -f "$INSTALL_DIR/lib/lua/$LUAV/mime/core.so" ] || { echo "Error: mime/core.so isn't found"; exit 1; }
  [ -f "$INSTALL_DIR/lib/lua/$LUAV/socket/core.so" ] || { echo "Error: socket/core.so isn't found"; exit 1; }
  cd ..
  rm -rf "$LUASOCKET_FILENAME" "$LUASOCKET_BASENAME"
fi

# now copy the compiled dependencies to ZBS binary directory
mkdir -p "$BIN_DIR" || { echo "Error: cannot create directory $BIN_DIR"; exit 1; }
[ $BUILD_LUA ] && cp "$INSTALL_DIR/bin/lua$LUAS" "$BIN_DIR"
[ $BUILD_WXLUA ] && cp "$INSTALL_DIR/lib/libwx.so" "$BIN_DIR"
if [ $BUILD_LUASOCKET ]; then
  mkdir -p "$BIN_DIR/clibs$LUAS/"{mime,socket}
  cp "$INSTALL_DIR/lib/lua/$LUAV/mime/core.so" "$BIN_DIR/clibs$LUAS/mime"
  cp "$INSTALL_DIR/lib/lua/$LUAV/socket/core.so" "$BIN_DIR/clibs$LUAS/socket"
fi

echo "*** Build has been successfully completed ***"
exit 0
