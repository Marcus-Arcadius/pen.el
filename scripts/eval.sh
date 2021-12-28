#!/bin/bash

{
stty stop undef; stty start undef
} 2>/dev/null

# Debian10 run Pen

# export PEN_DEBUG=y

export LANG=en_US
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

: "${SOCKET:="DEFAULT"}"

while [ $# -gt 0 ]; do opt="$1"; case "$opt" in
    "") { shift; }; ;;
    -D) {
        SOCKET="$2"
        shift
        shift
    }
    ;;

    --parallel|--pool) {
        export USE_POOL=y
        shift
    }
    ;;

    *) break;
esac; done

export EMACSD=/root/.emacs.d
export YAMLMOD_PATH=$EMACSD/emacs-yamlmod
export PATH=$PATH:$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts

last_arg="${@: -1}"
last_arg="$(p "$last_arg" | pen-bs '\\')"

fp="/tmp/eval-output-${SOCKET}.txt"
rm -f "$fp"
# Can't use cmd because elisp doesn't use single quote for strings
unbuffer emacsclient -a "" -s ~/.emacs.d/server/$SOCKET -e "(pen-eval-for-host \"$SOCKET\" $last_arg)" &>/dev/null
sleep 0.1

# I need to hide the fact that it failed. Otherwise, I can't cancel comint commands without polluting the repl
cat "$fp" 2>/dev/null
