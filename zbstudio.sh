#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # per http://stackoverflow.com/a/246128
CWD="$PWD" # save the current directory, as it's going to change

if [[ $(uname) == "Darwin" ]]; then
  # MacOS Sierra throws `error -10810` running with quarantined files even when explicitly allowed
  ATTR="com.apple.quarantine"
  (cd "$DIR"; \
   if [[ $( xattr -pl $ATTR zbstudio 2>&1 ) == $ATTR:* ]]; then xattr -rd $ATTR zbstudio bin; fi; \
   open zbstudio/ZeroBraneStudio.app --args -cwd "$CWD" "$@")
else
  case "$(uname -m)" in
    x86_64)  ARCH=x64;;
    armv7l)  ARCH=armhf;;
    aarch64) ARCH=aarch64;;
    *)       ARCH=x86;;
  esac
  (cd "$DIR"; bin/linux/$ARCH/lua src/main.lua zbstudio -cwd "$CWD" "$@") &
fi
