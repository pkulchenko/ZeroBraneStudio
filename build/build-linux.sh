#!/bin/bash

# exit if the command line is empty
if [ $# -eq 0 ]; then
  echo "Usage: $0 LIBRARY..."
  exit 0
fi

case "$(uname -m)" in
	x86_64)
		FPIC="-fpic"
		ARCH="x64"
		;;
	armv7l)
		FPIC="-fpic"
		ARCH="armhf"
		;;
        aarch64)
		FPIC="-fpic"
		ARCH="aarch64"
		;;
	*)
		FPIC=""
		ARCH="x86"
		;;
esac

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # per http://stackoverflow.com/a/246128

# binary directory
BIN_DIR="$(dirname "$DIR")/bin/linux/$ARCH"

# temporary installation directory for dependencies
INSTALL_DIR="$DIR/deps"

# number of parallel jobs used for building
MAKEFLAGS="-j4"

# flags for manual building with gcc
BUILD_FLAGS="-Os -shared -s -I $INSTALL_DIR/include -L $INSTALL_DIR/lib $FPIC"

# paths configuration
WXWIDGETS_BASENAME="wxWidgets"
WXWIDGETS_URL="https://github.com/pkulchenko/wxWidgets.git"

WXLUA_BASENAME="wxlua"
WXLUA_URL="https://github.com/pkulchenko/wxlua.git"

LUASOCKET_BASENAME="luasocket-3.0-rc1"
LUASOCKET_FILENAME="v3.0-rc1.zip"
LUASOCKET_URL="https://github.com/diegonehab/luasocket/archive/$LUASOCKET_FILENAME"

OPENSSL_BASENAME="openssl-1.1.1d"
OPENSSL_FILENAME="$OPENSSL_BASENAME.tar.gz"
OPENSSL_URL="http://www.openssl.org/source/$OPENSSL_FILENAME"

LUASEC_BASENAME="luasec-0.9"
LUASEC_FILENAME="v0.9.zip"
LUASEC_URL="https://github.com/brunoos/luasec/archive/$LUASEC_FILENAME"

LFS_BASENAME="v_1_6_3"
LFS_FILENAME="$LFS_BASENAME.tar.gz"
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
    WXWIDGETSDEBUG="--enable-debug=max --enable-debug_gdb"
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

# check for git
if [ ! "$(which git)" ]; then
  echo "Error: git isn't found. Please install console GIT client."
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
    wget -c "$LUA_URL" -O "$LUA_FILENAME" || { echo "Error: failed to download Lua"; exit 1; }
    tar -xzf "$LUA_FILENAME"
  fi
  cd "$LUA_BASENAME"

  if [ $BUILD_JIT ]; then
    make CCOPT="-DLUAJIT_ENABLE_LUA52COMPAT" || { echo "Error: failed to build Lua"; exit 1; }
    make install PREFIX="$INSTALL_DIR"
    cp "$INSTALL_DIR"/bin/luajit "$INSTALL_DIR/bin/lua"
    # don't copy luajit includes as the libraries should be compiled using Lua headers
  else
    # use POSIX as it has minimum dependencies (no readline and no ncurses required)
    # LUA_USE_DLOPEN is required for loading libraries
    (cd src; make all MYCFLAGS="$FPIC -DLUA_USE_POSIX -DLUA_USE_DLOPEN" MYLIBS="-Wl,-E -ldl") || { echo "Error: failed to build Lua"; exit 1; }
    make install INSTALL_TOP="$INSTALL_DIR"
  fi
  cp "$INSTALL_DIR/bin/lua" "$INSTALL_DIR/bin/lua$LUAV"
  [ $DEBUGBUILD ] || strip --strip-unneeded "$INSTALL_DIR/bin/lua$LUAV"

  cd ..
  rm -rf "$LUA_FILENAME" "$LUA_BASENAME"
fi

# build lexlpeg
if [ $BUILD_LEXLPEG ]; then
  # need wxwidgets/Scintilla and lua files
  git clone "$WXWIDGETS_URL" "$WXWIDGETS_BASENAME" || { echo "Error: failed to get wxWidgets"; exit 1; }
  wget --no-check-certificate -c "$LEXLPEG_URL" -O "$LEXLPEG_FILENAME" || { echo "Error: failed to download LexLPeg"; exit 1; }
  unzip "$LEXLPEG_FILENAME"
  cd "scintillua-$LEXLPEG_BASENAME"

  # replace loading lpeg with os and debug as they are needed for debugging;
  # loading lpeg is not needed as it will be loaded from the Lua module.
  sed -i 's/luaopen_lpeg, "lpeg"/luaopen_os, LUA_OSLIBNAME); l_openlib(luaopen_debug, LUA_DBLIBNAME/' LexLPeg.cxx

  mkdir -p "$INSTALL_DIR/lib/lua/$LUAV/"
  g++ $BUILD_FLAGS -o "$INSTALL_DIR/lib/lua/$LUAV/lexlpeg.so" \
    "-I../$WXWIDGETS_BASENAME/src/stc/scintilla/include" "-I../$WXWIDGETS_BASENAME/src/stc/scintilla/lexlib/" \
    -DSCI_LEXER -DLPEG_LEXER -DLPEG_LEXER_EXTERNAL \
    LexLPeg.cxx ../$WXWIDGETS_BASENAME/src/stc/scintilla/lexlib/{PropSetSimple.cxx,WordList.cxx,LexerModule.cxx,LexerSimple.cxx,LexerBase.cxx,Accessor.cxx}

  [ -f "$INSTALL_DIR/lib/lua/$LUAV/lexlpeg.so" ] || { echo "Error: LexLPeg.so isn't found"; exit 1; }
  [ $DEBUGBUILD ] || strip --strip-unneeded "$INSTALL_DIR/lib/lua/$LUAV/lexlpeg.so"

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

  ./configure --prefix="$INSTALL_DIR" $WXWIDGETSDEBUG --disable-shared --enable-unicode \
    --enable-compat30 \
    --enable-privatefonts \
    --with-libjpeg=builtin --with-libpng=builtin --with-libtiff=builtin --with-expat=builtin \
    --with-zlib=builtin --disable-richtext --with-gtk=3 \
    CFLAGS="-Os -fPIC" CXXFLAGS="-Os -fPIC"

  PATTERN="defined( __WXGTK__)"
  if [ ! "$(sed -n "/$PATTERN/{N;/$PATTERN\n static/p;}" src/aui/tabart.cpp)" ]; then
    echo "Incorrect pattern for a fix in tabart.cpp."
    exit 1
  fi
  REPLACEMENT='0\
 static'
  sed -i "/$PATTERN/{N;s/$PATTERN\n static/$REPLACEMENT/;}" src/aui/tabart.cpp

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

  cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -DCMAKE_BUILD_TYPE=$WXLUABUILD -DBUILD_SHARED_LIBS=FALSE \
    -DCMAKE_SKIP_RPATH=TRUE \
    -DwxWidgets_CONFIG_EXECUTABLE="$INSTALL_DIR/bin/wx-config" \
    -DwxWidgets_COMPONENTS="xrc;xml;stc;gl;html;aui;adv;core;net;base" \
    -DwxLuaBind_COMPONENTS="xrc;xml;stc;gl;html;aui;adv;core;net;base" \
    -DwxLua_LUA_LIBRARY_USE_BUILTIN=FALSE \
    -DwxLua_LUA_INCLUDE_DIR="$INSTALL_DIR/include" -DwxLua_LUA_LIBRARY="$INSTALL_DIR/lib/liblua.a" .
  (cd modules/luamodule; make $MAKEFLAGS) || { echo "Error: failed to build wxLua"; exit 1; }
  (cd modules/luamodule; make install)
  [ -f "$INSTALL_DIR/lib/libwx.so" ] || { echo "Error: libwx.so isn't found"; exit 1; }
  [ $DEBUGBUILD ] || strip --strip-unneeded "$INSTALL_DIR/lib/libwx.so"
  cd ../..
  rm -rf "$WXLUA_BASENAME"
fi

# build LuaSocket
if [ $BUILD_LUASOCKET ]; then
  wget --no-check-certificate -c "$LUASOCKET_URL" -O "$LUASOCKET_FILENAME" || { echo "Error: failed to download LuaSocket"; exit 1; }
  unzip "$LUASOCKET_FILENAME"
  cd "$LUASOCKET_BASENAME"
  mkdir -p "$INSTALL_DIR/lib/lua/$LUAV/"{mime,socket}
  gcc $BUILD_FLAGS -o "$INSTALL_DIR/lib/lua/$LUAV/mime/core.so" src/mime.c \
    || { echo "Error: failed to build LuaSocket"; exit 1; }
  gcc $BUILD_FLAGS -o "$INSTALL_DIR/lib/lua/$LUAV/socket/core.so" \
    src/{auxiliar.c,buffer.c,except.c,inet.c,io.c,luasocket.c,options.c,select.c,tcp.c,timeout.c,udp.c,usocket.c} \
    || { echo "Error: failed to build LuaSocket"; exit 1; }
  mkdir -p "$INSTALL_DIR/share/lua/$LUAV/socket"
  cp src/{headers.lua,ftp.lua,http.lua,smtp.lua,tp.lua,url.lua} "$INSTALL_DIR/share/lua/$LUAV/socket"
  cp src/{ltn12.lua,mime.lua,socket.lua} "$INSTALL_DIR/share/lua/$LUAV"
  [ -f "$INSTALL_DIR/lib/lua/$LUAV/mime/core.so" ] || { echo "Error: mime/core.so isn't found"; exit 1; }
  [ -f "$INSTALL_DIR/lib/lua/$LUAV/socket/core.so" ] || { echo "Error: socket/core.so isn't found"; exit 1; }
  [ $DEBUGBUILD ] || strip --strip-unneeded "$INSTALL_DIR/bin/lua/$LUAV/socket/core.so" "$INSTALL_DIR/bin/lua/$LUAV/mime/core.so"
  cd ..
  rm -rf "$LUASOCKET_FILENAME" "$LUASOCKET_BASENAME"
fi

# build lfs
if [ $BUILD_LFS ]; then
  wget --no-check-certificate -c "$LFS_URL" -O "$LFS_FILENAME" || { echo "Error: failed to download lfs"; exit 1; }
  tar -xzf "$LFS_FILENAME"
  mv "luafilesystem-$LFS_BASENAME" "$LFS_BASENAME"
  cd "$LFS_BASENAME/src"
  mkdir -p "$INSTALL_DIR/lib/lua/$LUAV/"
  gcc $BUILD_FLAGS -o "$INSTALL_DIR/lib/lua/$LUAV/lfs.so" lfs.c \
    || { echo "Error: failed to build lfs"; exit 1; }
  [ -f "$INSTALL_DIR/lib/lua/$LUAV/lfs.so" ] || { echo "Error: lfs.so isn't found"; exit 1; }
  [ $DEBUGBUILD ] || strip --strip-unneeded "$INSTALL_DIR/lib/lua/$LUAV/lfs.so"
  cd ../..
  rm -rf "$LFS_FILENAME" "$LFS_BASENAME"
fi

# build lpeg
if [ $BUILD_LPEG ]; then
  wget --no-check-certificate -c "$LPEG_URL" -O "$LPEG_FILENAME" || { echo "Error: failed to download lpeg"; exit 1; }
  tar -xzf "$LPEG_FILENAME"
  cd "$LPEG_BASENAME"
  mkdir -p "$INSTALL_DIR/lib/lua/$LUAV/"
  gcc $BUILD_FLAGS -o "$INSTALL_DIR/lib/lua/$LUAV/lpeg.so" lptree.c lpvm.c lpcap.c lpcode.c lpprint.c \
    || { echo "Error: failed to build lpeg"; exit 1; }
  [ -f "$INSTALL_DIR/lib/lua/$LUAV/lpeg.so" ] || { echo "Error: lpeg.so isn't found"; exit 1; }
  [ $DEBUGBUILD ] || strip --strip-unneeded "$INSTALL_DIR/bin/lua/$LUAV/lpeg.so"
  cd ..
  rm -rf "$LPEG_FILENAME" "$LPEG_BASENAME"
fi

# build LuaSec
if [ $BUILD_LUASEC ]; then
  # build openSSL
  wget --no-check-certificate -c "$OPENSSL_URL" -O "$OPENSSL_FILENAME" || { echo "Error: failed to download OpenSSL"; exit 1; }
  tar -xzf "$OPENSSL_FILENAME"
  cd "$OPENSSL_BASENAME"
  ./config shared

  make depend
  make
  make install_sw INSTALLTOP="$INSTALL_DIR"
  [ $DEBUGBUILD ] || strip --strip-unneeded "$INSTALL_DIR/lib/libcrypto.so" "$INSTALL_DIR/lib/libssl.so"
  cd ..
  rm -rf "$OPENSSL_FILENAME" "$OPENSSL_BASENAME"

  # build LuaSec
  wget --no-check-certificate -c "$LUASEC_URL" -O "$LUASEC_FILENAME" || { echo "Error: failed to download LuaSec"; exit 1; }
  unzip "$LUASEC_FILENAME"
  cd "$LUASEC_BASENAME"
  mkdir -p "$INSTALL_DIR/lib/lua/$LUAV/"
  gcc $BUILD_FLAGS -o "$INSTALL_DIR/lib/lua/$LUAV/ssl.so" \
    src/luasocket/{timeout.c,buffer.c,io.c,usocket.c} src/{config.c,options.c,context.c,ec.c,x509.c,ssl.c} -Isrc \
    -Wl,-rpath,'$ORIGIN' -Wl,-rpath,'$ORIGIN/..' \
    -lssl -lcrypto \
    || { echo "Error: failed to build LuaSec"; exit 1; }
  mkdir -p "$INSTALL_DIR/share/lua/$LUAV/"
  cp src/ssl.lua "$INSTALL_DIR/share/lua/$LUAV/"
  mkdir -p "$INSTALL_DIR/share/lua/$LUAV/ssl"
  cp src/https.lua "$INSTALL_DIR/share/lua/$LUAV/ssl/"
  [ -f "$INSTALL_DIR/lib/lua/$LUAV/ssl.so" ] || { echo "Error: ssl.so isn't found"; exit 1; }
  [ $DEBUGBUILD ] || strip --strip-unneeded "$INSTALL_DIR/lib/lua/$LUAV/ssl.so"
  cd ..
  rm -rf "$LUASEC_FILENAME" "$LUASEC_BASENAME"
fi

[ -d "$BIN_DIR/clibs" ] || mkdir -p "$BIN_DIR/clibs" || { echo "Error: cannot create directory $BIN_DIR/clibs"; exit 1; }
if [ $LUAS ]; then
  [ -d "$BIN_DIR/clibs$LUAS" ] || mkdir -p "$BIN_DIR/clibs$LUAS" || { echo "Error: cannot create directory $BIN_DIR/clibs$LUAS"; exit 1; }
fi

# now copy the compiled dependencies to the correct locations
[ $BUILD_LUA ] && cp "$INSTALL_DIR/bin/lua$LUAS" "$BIN_DIR"
[ $BUILD_WXLUA ] && cp "$INSTALL_DIR/lib/libwx.so" "$BIN_DIR/clibs"
[ $BUILD_LFS ] && cp "$INSTALL_DIR/lib/lua/$LUAV/lfs.so" "$BIN_DIR/clibs$LUAS"
[ $BUILD_LPEG ] && cp "$INSTALL_DIR/lib/lua/$LUAV/lpeg.so" "$BIN_DIR/clibs$LUAS"
[ $BUILD_LEXLPEG ] && cp "$INSTALL_DIR/lib/lua/$LUAV/lexlpeg.so" "$BIN_DIR/clibs$LUAS"

if [ $BUILD_LUASOCKET ]; then
  mkdir -p "$BIN_DIR/clibs$LUAS/"{mime,socket}
  cp "$INSTALL_DIR/lib/lua/$LUAV/mime/core.so" "$BIN_DIR/clibs$LUAS/mime"
  cp "$INSTALL_DIR/lib/lua/$LUAV/socket/core.so" "$BIN_DIR/clibs$LUAS/socket"
fi

if [ $BUILD_LUASEC ]; then
  cp "$INSTALL_DIR/lib/libcrypto.so" "$BIN_DIR/libcrypto.so.1.1"
  cp "$INSTALL_DIR/lib/libssl.so" "$BIN_DIR/libssl.so.1.1"
  cp "$INSTALL_DIR/lib/lua/$LUAV/ssl.so" "$BIN_DIR/clibs$LUAS"
  cp "$INSTALL_DIR/share/lua/$LUAV/ssl.lua" ../lualibs
  cp "$INSTALL_DIR/share/lua/$LUAV/ssl/https.lua" ../lualibs/ssl
fi

echo "*** Build has been successfully completed ***"
exit 0
