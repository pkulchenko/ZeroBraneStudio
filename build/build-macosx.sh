#!/bin/bash

# exit if the command line is empty
if [ $# -eq 0 ]; then
  echo "Usage: $0 LIBRARY..."
  exit 0
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # per http://stackoverflow.com/a/246128

# binary directory
BIN_DIR="$(dirname "$DIR")/bin"

# temporary installation directory for dependencies
INSTALL_DIR="$DIR/deps"

# Mac OS X global settings
MACOSX_ARCH="x86_64"
MACOSX_VERSION="10.10"
MACOSX_SDK_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.14.sdk"

# number of parallel jobs used for building
MAKEFLAGS="-j4"

# flags for manual building with gcc; build universal binaries for luasocket
MACOSX_FLAGS="-arch $MACOSX_ARCH -mmacosx-version-min=$MACOSX_VERSION"
if [ -d "$MACOSX_SDK_PATH" ]; then
  echo "Building with $MACOSX_SDK_PATH"
  MACOSX_FLAGS="$MACOSX_FLAGS -isysroot $MACOSX_SDK_PATH"
fi
BUILD_FLAGS="-Os -dynamiclib -undefined dynamic_lookup $MACOSX_FLAGS -I $INSTALL_DIR/include -L $INSTALL_DIR/lib"

# paths configuration
WXWIDGETS_BASENAME="wxWidgets"
WXWIDGETS_URL="https://github.com/pkulchenko/wxWidgets.git"

WXLUA_BASENAME="wxlua"
WXLUA_URL="https://github.com/pkulchenko/wxlua.git"

LUASOCKET_BASENAME="luasocket-3.1.0"
LUASOCKET_FILENAME="v3.1.0.zip"
LUASOCKET_URL="https://github.com/lunarmodules/luasocket/archive/refs/tags/$LUASOCKET_FILENAME"

OPENSSL_BASENAME="openssl-1.1.1d"
OPENSSL_FILENAME="$OPENSSL_BASENAME.tar.gz"
OPENSSL_URL="http://www.openssl.org/source/$OPENSSL_FILENAME"

LUASEC_BASENAME="luasec-0.9"
LUASEC_FILENAME="v0.9.zip"
LUASEC_URL="https://github.com/brunoos/luasec/archive/$LUASEC_FILENAME"

LFS_BASENAME="1_8_0"
LFS_FILENAME="v$LFS_BASENAME.tar.gz"
LFS_URL="https://github.com/keplerproject/luafilesystem/archive/$LFS_FILENAME"

LPEG_BASENAME="lpeg-1.0.0"
LPEG_FILENAME="$LPEG_BASENAME.tar.gz"
LPEG_URL="http://www.inf.puc-rio.br/~roberto/lpeg/$LPEG_FILENAME"

LEXLPEG_BASENAME="scintillua_3.6.5-1"
LEXLPEG_FILENAME="$LEXLPEG_BASENAME.zip"
LEXLPEG_URL="https://github.com/orbitalquark/scintillua/archive/refs/tags/$LEXLPEG_FILENAME"

WXWIDGETSDEBUG="--disable-debug"
WXLUABUILD="MinSizeRel"

# iterate through the command line arguments
for ARG in "$@"; do
  case $ARG in
  5.2)
    BUILD_LUA=true
    BUILD_52=true
    ;;
  5.3)
    BUILD_LUA=true
    BUILD_53=true
    BUILD_FLAGS="$BUILD_FLAGS -DLUA_COMPAT_APIINTCASTS"
    ;;
  5.4)
    BUILD_LUA=true
    BUILD_54=true
    BUILD_FLAGS="$BUILD_FLAGS -DLUA_COMPAT_APIINTCASTS"
    ;;
  jit)
    BUILD_LUA=true
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
  luasec)
    BUILD_LUASEC=true
    ;;
  luasocket)
    BUILD_LUASOCKET=true
    ;;
  lfs)
    BUILD_LFS=true
    ;;
  lpeg)
    BUILD_LPEG=true
    ;;
  lexlpeg)
    BUILD_LEXLPEG=true
    ;;
  debug)
    WXWIDGETSDEBUG="--enable-debug=max"
    WXLUABUILD="Debug"
    DEBUGBUILD=true
    ;;
  all)
    BUILD_WXWIDGETS=true
    BUILD_LUA=true
    BUILD_WXLUA=true
    BUILD_LUASOCKET=true
    BUILD_LUASEC=true
    BUILD_LFS=true
    BUILD_LPEG=true
    BUILD_LEXLPEG=true
    ;;
  *)
    echo "Error: invalid argument $ARG"
    exit 1
    ;;
  esac
done

if [ ! "$(which g++)" ]; then
  echo "Error: g++ isn't found. Please install GNU C++ compiler."
  exit 1
fi

if [ ! "$(which cmake)" ]; then
  echo "Error: cmake isn't found. Please install CMake and add it to PATH."
  exit 1
fi

if [ ! "$(which git)" ]; then
  echo "Error: git isn't found. Please install console GIT client."
  exit 1
fi

if [ ! "$(which curl)" ]; then
  echo "Error: curl isn't found. Please install curl."
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
  LUA_BASENAME="lua-5.3.6"
  LUA_FILENAME="$LUA_BASENAME.tar.gz"
  LUA_URL="http://www.lua.org/ftp/$LUA_FILENAME"
  LUA_COMPAT="MYCFLAGS=-DLUA_COMPAT_MODULE"
fi

if [ $BUILD_54 ]; then
  LUAV="54"
  LUAS=$LUAV
  LUA_BASENAME="lua-5.4.6"
  LUA_FILENAME="$LUA_BASENAME.tar.gz"
  LUA_URL="http://www.lua.org/ftp/$LUA_FILENAME"
  LUA_COMPAT="MYCFLAGS=-DLUA_COMPAT_MODULE"
fi

if [ $BUILD_JIT ]; then
  LUA_BASENAME="luajit"
  LUA_URL="https://github.com/pkulchenko/luajit.git"
fi

# build Lua
if [ $BUILD_LUA ]; then
  if [ $BUILD_JIT ]; then
    git clone "$LUA_URL" "$LUA_BASENAME"
    (cd "$LUA_BASENAME"; git checkout v2.0.4)
  else
    curl -L "$LUA_URL" > "$LUA_FILENAME" || { echo "Error: failed to download Lua"; exit 1; }
    tar -xzf "$LUA_FILENAME"
  fi
  cd "$LUA_BASENAME"

  if [ $BUILD_JIT ]; then
    make BUILDMODE=dynamic LUAJIT_SO=liblua.dylib MACOSX_DEPLOYMENT_TARGET=$MACOSX_VERSION TARGET_DYLIBPATH=liblua.dylib CC="gcc" CCOPT="$MACOSX_FLAGS -DLUAJIT_ENABLE_LUA52COMPAT" || { echo "Error: failed to build Lua"; exit 1; }
    make install PREFIX="$INSTALL_DIR"
    cp "src/luajit" "$INSTALL_DIR/bin/lua"
    cp "src/liblua.dylib" "$INSTALL_DIR/lib"
  else
    sed -i "" 's/PLATS=/& macosx_dylib/' Makefile

    # -O1 fixes this issue with for Lua 5.2 with i386: http://lua-users.org/lists/lua-l/2013-05/msg00070.html
    printf "macosx_dylib:\n" >> src/Makefile
    printf "\t\$(MAKE) LUA_A=\"liblua$LUAS.dylib\" AR=\"\$(CC) -dynamiclib $MACOSX_FLAGS -o\" RANLIB=\"strip -u -r\" \\\\\n" >> src/Makefile
    printf "\tMYCFLAGS=\"-O1 -DLUA_USE_LINUX $MACOSX_FLAGS\" MYLDFLAGS=\"$MACOSX_FLAGS\" MYLIBS=\"-lreadline\" lua\n" >> src/Makefile
    printf "\t\$(MAKE) MYCFLAGS=\"-DLUA_USE_LINUX $MACOSX_FLAGS\" MYLDFLAGS=\"$MACOSX_FLAGS\" luac\n" >> src/Makefile
    make macosx_dylib || { echo "Error: failed to build Lua"; exit 1; }
    make install INSTALL_TOP="$INSTALL_DIR"
    mv "$INSTALL_DIR/bin/lua" "$INSTALL_DIR/bin/lua$LUAS"
    cp src/liblua$LUAS.dylib "$INSTALL_DIR/lib"
  fi

  install_name_tool -change liblua$LUAS.dylib @rpath/liblua$LUAS.dylib "$INSTALL_DIR/bin/lua$LUAS"
  install_name_tool -add_rpath @executable_path/../../.. "$INSTALL_DIR/bin/lua$LUAS"
  install_name_tool -add_rpath @executable_path/. "$INSTALL_DIR/bin/lua$LUAS"

  [ $DEBUGBUILD ] || strip -u -r "$INSTALL_DIR/bin/lua$LUAS"
  [ -f "$INSTALL_DIR/lib/liblua$LUAS.dylib" ] || { echo "Error: liblua$LUAS.dylib isn't found"; exit 1; }
  cd ..
  rm -rf "$LUA_FILENAME" "$LUA_BASENAME"
fi

# build lexlpeg
if [ $BUILD_LEXLPEG ]; then
  # need wxwidgets/Scintilla and lua files
  git clone "$WXWIDGETS_URL" "$WXWIDGETS_BASENAME" || { echo "Error: failed to get wxWidgets"; exit 1; }
  curl -L "$LEXLPEG_URL" > "$LEXLPEG_FILENAME" || { echo "Error: failed to download LexLPeg"; exit 1; }
  unzip "$LEXLPEG_FILENAME"
  cd "scintillua-$LEXLPEG_BASENAME"

  # comment out loading lpeg as it's causing issues with _luaopen_lpeg symbol
  # (as it's not statically compiled) and will be loaded from Lua code anyway
  sed -i "" 's/luaopen_lpeg, "lpeg"/luaopen_os, LUA_OSLIBNAME); l_openlib(luaopen_debug, LUA_DBLIBNAME/' LexLPeg.cxx

  mkdir -p "$INSTALL_DIR/lib/lua/$LUAV/"
  g++ $BUILD_FLAGS -install_name lexlpeg.dylib -o "$INSTALL_DIR/lib/lua/$LUAV/lexlpeg.dylib" \
    "-I../$WXWIDGETS_BASENAME/src/stc/scintilla/include" "-I../$WXWIDGETS_BASENAME/src/stc/scintilla/lexlib/" \
    -DSCI_LEXER -DLPEG_LEXER -DLPEG_LEXER_EXTERNAL \
    LexLPeg.cxx ../$WXWIDGETS_BASENAME/src/stc/scintilla/lexlib/{PropSetSimple.cxx,WordList.cxx,LexerModule.cxx,LexerSimple.cxx,LexerBase.cxx,Accessor.cxx}

  [ -f "$INSTALL_DIR/lib/lua/$LUAV/lexlpeg.dylib" ] || { echo "Error: LexLPeg.dylib isn't found"; exit 1; }
  [ $DEBUGBUILD ] || strip -u -r "$INSTALL_DIR/lib/lua/$LUAV/lexlpeg.dylib"

  cd ..
  rm -rf "scintillua-$LEXLPEG_BASENAME" "$LEXLPEG_FILENAME"
  # don't delete wxwidgets, if it's requested to be built
  [ $BUILD_WXWIDGETS ] || rm -rf "$WXWIDGETS_BASENAME"
fi

# build wxWidgets
if [ $BUILD_WXWIDGETS ]; then
  # don't clone again, as it's already cloned for lexlpeg
  [ $BUILD_LEXLPEG ] || git clone "$WXWIDGETS_URL" "$WXWIDGETS_BASENAME" || { echo "Error: failed to get wxWidgets"; exit 1; }
  cd "$WXWIDGETS_BASENAME"

  # checkout the version that was used in wxwidgets upgrade to 3.1.x
  git checkout master

  # refresh wxwidgets submodules
  git submodule update --init --recursive

  MINSDK=""
  if [ -d $MACOSX_SDK_PATH ]; then
    MINSDK="--with-macosx-sdk=$MACOSX_SDK_PATH"
  fi
  ./configure --prefix="$INSTALL_DIR" $WXWIDGETSDEBUG --disable-shared --enable-unicode \
    --enable-compat30 \
    --enable-privatefonts \
    --with-cxx=11 \
    --with-libjpeg=builtin --with-libpng=builtin --with-libtiff=builtin --with-expat=builtin \
    --with-zlib=builtin --disable-richtext \
    --enable-macosx_arch=$MACOSX_ARCH --with-macosx-version-min=$MACOSX_VERSION $MINSDK \
    --with-osx_cocoa CFLAGS="-Os" CXXFLAGS="-Os"

  PATTERN="defined( __WXMAC__ )"
  if [ ! "$(sed -n "/$PATTERN/{N;/$PATTERN\n static/p;}" src/aui/tabart.cpp)" ]; then
    echo "Incorrect pattern for a fix in tabart.cpp."
    exit 1
  fi
  REPLACEMENT='0\
 static'
  sed -i "" "/$PATTERN/{N;s/$PATTERN\n static/$REPLACEMENT/;}" src/aui/tabart.cpp

  make $MAKEFLAGS || { echo "Error: failed to build wxWidgets"; exit 1; }
  make install
  cd ..
  rm -rf "$WXWIDGETS_BASENAME"
fi

# build wxLua
if [ $BUILD_WXLUA ]; then
  git clone "$WXLUA_URL" "$WXLUA_BASENAME" || { echo "Error: failed to get wxlua"; exit 1; }
  cd "$WXLUA_BASENAME/wxLua"

  git checkout v3.0.0.8

  MINSDK=""
  if [ -d $MACOSX_SDK_PATH ]; then
    MINSDK="CMAKE_OSX_SYSROOT=$MACOSX_SDK_PATH"
  fi

  echo 'set_target_properties(wxLuaModule PROPERTIES LINK_FLAGS "-undefined dynamic_lookup -image_base 100000000")' >> modules/luamodule/CMakeLists.txt
  cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -DCMAKE_BUILD_TYPE=$WXLUABUILD -DBUILD_SHARED_LIBS=FALSE \
    -DCMAKE_SKIP_RPATH=TRUE \
    -DCMAKE_OSX_ARCHITECTURES=$MACOSX_ARCH -DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOSX_VERSION $MINSDK \
    -DCMAKE_C_COMPILER=/usr/bin/gcc -DCMAKE_CXX_COMPILER=/usr/bin/g++ -DwxWidgets_CONFIG_EXECUTABLE="$INSTALL_DIR/bin/wx-config" \
    -DCMAKE_CXX_FLAGS="-std=c++11 -stdlib=libc++" \
    -DwxWidgets_COMPONENTS="xrc;xml;stc;gl;html;aui;adv;core;net;base" \
    -DwxLuaBind_COMPONENTS="xrc;xml;stc;gl;html;aui;adv;core;net;base" \
    -DwxLua_LUA_LIBRARY_USE_BUILTIN=FALSE \
    -DwxLua_LUA_INCLUDE_DIR="$INSTALL_DIR/include" -DwxLua_LUA_LIBRARY="$INSTALL_DIR/lib/liblua.dylib" .
  (cd modules/luamodule; make $MAKEFLAGS) || { echo "Error: failed to build wxLua"; exit 1; }
  (cd modules/luamodule; make install)
  [ -f "$INSTALL_DIR/lib/libwx.dylib" ] || { echo "Error: libwx.dylib isn't found"; exit 1; }
  # update install name to remove absolute path
  install_name_tool -id libwx.dylib "$INSTALL_DIR/lib/libwx.dylib"
  [ $DEBUGBUILD ] || strip -u -r "$INSTALL_DIR/lib/libwx.dylib"
  cd ../..
  rm -rf "$WXLUA_BASENAME"
fi

# build LuaSocket
if [ $BUILD_LUASOCKET ]; then
  curl -L "$LUASOCKET_URL" > "$LUASOCKET_FILENAME" || { echo "Error: failed to download LuaSocket"; exit 1; }
  unzip "$LUASOCKET_FILENAME"
  cd "$LUASOCKET_BASENAME"
  mkdir -p "$INSTALL_DIR/lib/lua/$LUAV/"{mime,socket}
  gcc $BUILD_FLAGS -install_name core.dylib -o "$INSTALL_DIR/lib/lua/$LUAV/mime/core.dylib" src/compat.c src/mime.c \
    || { echo "Error: failed to build LuaSocket"; exit 1; }
  gcc $BUILD_FLAGS -install_name core.dylib -o "$INSTALL_DIR/lib/lua/$LUAV/socket/core.dylib" \
    src/{compat.c,auxiliar.c,buffer.c,except.c,inet.c,io.c,luasocket.c,options.c,select.c,tcp.c,timeout.c,udp.c,usocket.c} \
    || { echo "Error: failed to build LuaSocket"; exit 1; }
  mkdir -p "$INSTALL_DIR/share/lua/$LUAV/socket"
  cp src/{headers.lua,ftp.lua,http.lua,smtp.lua,tp.lua,url.lua} "$INSTALL_DIR/share/lua/$LUAV/socket"
  cp src/{ltn12.lua,mime.lua,socket.lua} "$INSTALL_DIR/share/lua/$LUAV"
  [ -f "$INSTALL_DIR/lib/lua/$LUAV/mime/core.dylib" ] || { echo "Error: mime/core.dylib isn't found"; exit 1; }
  [ -f "$INSTALL_DIR/lib/lua/$LUAV/socket/core.dylib" ] || { echo "Error: socket/core.dylib isn't found"; exit 1; }
  [ $DEBUGBUILD ] || strip -u -r "$INSTALL_DIR/lib/lua/$LUAV/mime/core.dylib" "$INSTALL_DIR/lib/lua/$LUAV/socket/core.dylib"
  cd ..
  rm -rf "$LUASOCKET_FILENAME" "$LUASOCKET_BASENAME"
fi

# build lfs
if [ $BUILD_LFS ]; then
  curl -L "$LFS_URL" > "$LFS_FILENAME" || { echo "Error: failed to download lfs"; exit 1; }
  tar -xzf "$LFS_FILENAME"
  mv "luafilesystem-$LFS_BASENAME" "$LFS_BASENAME"
  cd "$LFS_BASENAME/src"
  mkdir -p "$INSTALL_DIR/lib/lua/$LUAV/"
  gcc $BUILD_FLAGS -install_name lfs.dylib -o "$INSTALL_DIR/lib/lua/$LUAV/lfs.dylib" lfs.c \
    || { echo "Error: failed to build lfs"; exit 1; }
  [ -f "$INSTALL_DIR/lib/lua/$LUAV/lfs.dylib" ] || { echo "Error: lfs.dylib isn't found"; exit 1; }
  [ $DEBUGBUILD ] || strip -u -r "$INSTALL_DIR/lib/lua/$LUAV/lfs.dylib"
  cd ../..
  rm -rf "$LFS_FILENAME" "$LFS_BASENAME"
fi

# build lpeg
if [ $BUILD_LPEG ]; then
  curl -L "$LPEG_URL" > "$LPEG_FILENAME" || { echo "Error: failed to download lpeg"; exit 1; }
  tar -xzf "$LPEG_FILENAME"
  cd "$LPEG_BASENAME"
  mkdir -p "$INSTALL_DIR/lib/lua/$LUAV/"
  gcc $BUILD_FLAGS -install_name lpeg.dylib -o "$INSTALL_DIR/lib/lua/$LUAV/lpeg.dylib" lptree.c lpvm.c lpcap.c lpcode.c lpprint.c \
    || { echo "Error: failed to build lpeg"; exit 1; }
  [ -f "$INSTALL_DIR/lib/lua/$LUAV/lpeg.dylib" ] || { echo "Error: lpeg.dylib isn't found"; exit 1; }
  [ $DEBUGBUILD ] || strip -u -r "$INSTALL_DIR/lib/lua/$LUAV/lpeg.dylib"
  cd ..
  rm -rf "$LPEG_FILENAME" "$LPEG_BASENAME"
fi

# build LuaSec
if [ $BUILD_LUASEC ]; then
  # build openSSL
  curl -L "$OPENSSL_URL" > "$OPENSSL_FILENAME" || { echo "Error: failed to download OpenSSL"; exit 1; }
  tar -xzf "$OPENSSL_FILENAME"
  cd "$OPENSSL_BASENAME"
  perl ./Configure darwin64-x86_64-cc shared
  # add minimal macos SDK
  sed -ie "s!^CNF_CFLAGS=!CNF_CFLAGS=${MACOSX_FLAGS} !" Makefile

  make depend
  make
  make install_sw INSTALLTOP="$INSTALL_DIR"
  install_name_tool -id libcrypto.dylib "$INSTALL_DIR/lib/libcrypto.dylib"
  install_name_tool -id libssl.dylib "$INSTALL_DIR/lib/libssl.dylib"
  install_name_tool -change /usr/local/lib/libcrypto.1.1.dylib @loader_path/libcrypto.dylib "$INSTALL_DIR/lib/libssl.dylib"
  otool -L "$INSTALL_DIR/lib/libssl.dylib" | grep "loader_path/libcrypto" \
    || { echo "Error: failed to update libssl for libcrypto @loader_path"; exit 1; }
  [ $DEBUGBUILD ] || strip -u -r "$INSTALL_DIR/lib/libcrypto.dylib" "$INSTALL_DIR/lib/libssl.dylib"
  cd ..
  rm -rf "$OPENSSL_FILENAME" "$OPENSSL_BASENAME"

  # build LuaSec
  curl -L "$LUASEC_URL" > "$LUASEC_FILENAME" || { echo "Error: failed to download LuaSec"; exit 1; }
  unzip "$LUASEC_FILENAME"
  cd "$LUASEC_BASENAME"
  mkdir -p "$INSTALL_DIR/lib/lua/$LUAV/"
  gcc $BUILD_FLAGS -install_name ssl.dylib -o "$INSTALL_DIR/lib/lua/$LUAV/ssl.dylib" \
    src/luasocket/{timeout.c,buffer.c,io.c,usocket.c} src/{config.c,options.c,context.c,ec.c,x509.c,ssl.c} -Isrc \
    -L"$INSTALL_DIR/lib/" -lssl -lcrypto \
    -Wl,-headerpad_max_install_names \
    || { echo "Error: failed to build LuaSec"; exit 1; }
  mkdir -p "$INSTALL_DIR/share/lua/$LUAV/"
  cp src/ssl.lua "$INSTALL_DIR/share/lua/$LUAV/"
  mkdir -p "$INSTALL_DIR/share/lua/$LUAV/ssl"
  cp src/https.lua "$INSTALL_DIR/share/lua/$LUAV/ssl/"
  [ -f "$INSTALL_DIR/lib/lua/$LUAV/ssl.dylib" ] || { echo "Error: ssl.dylib isn't found"; exit 1; }
  install_name_tool -change libcrypto.dylib @rpath/libcrypto.dylib "$INSTALL_DIR/lib/lua/$LUAV/ssl.dylib"
  otool -L "$INSTALL_DIR/lib/lua/$LUAV/ssl.dylib" | grep "rpath/libcrypto" \
    || { echo "Error: failed to update ssl library for libcrypto @rpath"; exit 1; }
  install_name_tool -change libssl.dylib @rpath/libssl.dylib "$INSTALL_DIR/lib/lua/$LUAV/ssl.dylib"
  otool -L "$INSTALL_DIR/lib/lua/$LUAV/ssl.dylib" | grep "rpath/libssl" \
    || { echo "Error: failed to update ssl library for libssl @rpath"; exit 1; }
  install_name_tool -add_rpath @loader_path/. "$INSTALL_DIR/lib/lua/$LUAV/ssl.dylib"
  install_name_tool -add_rpath @loader_path/.. "$INSTALL_DIR/lib/lua/$LUAV/ssl.dylib"
  [ $DEBUGBUILD ] || strip -u -r "$INSTALL_DIR/lib/lua/$LUAV/ssl.dylib"
  cd ..
  rm -rf "$LUASEC_FILENAME" "$LUASEC_BASENAME"
fi

[ -d "$BIN_DIR/clibs" ] || mkdir -p "$BIN_DIR/clibs" || { echo "Error: cannot create directory $BIN_DIR/clibs"; exit 1; }
if [ $LUAS ]; then
  [ -d "$BIN_DIR/clibs$LUAS" ] || mkdir -p "$BIN_DIR/clibs$LUAS" || { echo "Error: cannot create directory $BIN_DIR/clibs$LUAS"; exit 1; }
fi

# now copy the compiled dependencies to the correct locations
if [ $BUILD_LUA ]; then
  mkdir -p "$BIN_DIR/lua.app/Contents/MacOS"
  cp "$INSTALL_DIR/bin/lua$LUAS" "$BIN_DIR/lua.app/Contents/MacOS"
  cp "$INSTALL_DIR/bin/lua$LUAS" "$INSTALL_DIR/lib/liblua$LUAS.dylib" "$BIN_DIR"
fi
[ $BUILD_WXLUA ] && cp "$INSTALL_DIR/lib/libwx.dylib" "$BIN_DIR/clibs"
[ $BUILD_LFS ] && cp "$INSTALL_DIR/lib/lua/$LUAV/lfs.dylib" "$BIN_DIR/clibs$LUAS"
[ $BUILD_LPEG ] && cp "$INSTALL_DIR/lib/lua/$LUAV/lpeg.dylib" "$BIN_DIR/clibs$LUAS"
[ $BUILD_LEXLPEG ] && cp "$INSTALL_DIR/lib/lua/$LUAV/lexlpeg.dylib" "$BIN_DIR/clibs$LUAS"

if [ $BUILD_LUASOCKET ]; then
  mkdir -p "$BIN_DIR/clibs$LUAS/"{mime,socket}
  cp "$INSTALL_DIR/lib/lua/$LUAV/mime/core.dylib" "$BIN_DIR/clibs$LUAS/mime"
  cp "$INSTALL_DIR/lib/lua/$LUAV/socket/core.dylib" "$BIN_DIR/clibs$LUAS/socket"
fi

if [ $BUILD_LUASEC ]; then
  cp "$INSTALL_DIR/lib/"{libcrypto.dylib,libssl.dylib} "$BIN_DIR"
  cp "$INSTALL_DIR/lib/lua/$LUAV/ssl.dylib" "$BIN_DIR/clibs$LUAS"
  cp "$INSTALL_DIR/share/lua/$LUAV/ssl.lua" ../lualibs
  cp "$INSTALL_DIR/share/lua/$LUAV/ssl/https.lua" ../lualibs/ssl
fi

echo "*** Build has been successfully completed ***"
exit 0
