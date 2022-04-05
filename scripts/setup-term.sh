#!/bin/bash
export TTY

# This script is sourced

{
stty stop undef; stty start undef
} 2>/dev/null

# Debian10 run Pen

# export PEN_DEBUG=y

export LANG=en_US
export TERM=screen-256color
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

export EMACSD=/root/.emacs.d
export YAMLMOD_PATH=$EMACSD/emacs-yamlmod
export PATH=$EMACSD/host/pen.el/scripts-host:$EMACSD/pen.el/scripts-host:$PATH
export PATH=$EMACSD/host/pen.el/scripts:$EMACSD/pen.el/scripts:$PATH
export PATH=$EMACSD/host/pen.el/scripts/container:$EMACSD/pen.el/scripts/container:$PATH
export PATH="$PATH:/root/go/bin"
export PATH="$PATH:/root/.cargo/bin/cargo"

if ! test -n "$PEN_DAEMON"; then
    . ~/.cargo/env
fi

# for ttyd
export LD_LIBRARY_PATH=/root/libwebsockets/build/lib:$LD_LIBRARY_PATH

export EDITOR=sps-w-pin
export BROWSER=sps-lg

[ -f "/root/.ghcup/env" ] && . "/root/.ghcup/env" # ghcup-env

# Needed for nlsh
export SHELL="$(basename $0)"