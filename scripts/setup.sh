#!/bin/bash

# Debian10 installation

export EMACSD=$HOME/.emacs.d
mkdir -p "$EMACSD"

agi() {
    apt install -y "$@"
}

cd
agi git python3 vim emacs mosh curl make xsel locales

locale-gen en_IN.utf-8
export LANG=en_US

# For nlsh and ii
agi rlwrap

# For emacs-yamlmod
agi clang libclang1

# For building emacs
# --with-modules is required to load emacs-yamlmod
agi autoconf texinfo libgnutls30 libgnutls28-dev pkg-config

agi python3-pip

# For lm-complete
pip3 install openai

# For tidy-prompt
pip3 install yq python-json2yaml

# For AIX API
pip3 install aixapi requests

pip3 install huggingface_hub

# For Pen.el
## slugify
agi libc-bin
## unbuffer
agi expect
## sponge
agi moreutils
agi jq
agi neovim

agi tmux

mkdir -p /root/org-roam

(
cd "$EMACSD"
test -d prompts || git clone --depth 1 "https://github.com/semiosis/prompts"
test -d engines || git clone --depth 1 "https://github.com/semiosis/engines"
test -d glossaries || git clone --depth 1 "https://github.com/semiosis/glossaries"
test -d emacs-yamlmod || git clone --depth 1 "https://github.com/perfectayush/emacs-yamlmod"
)

ln -sf ~/.emacs.d/pen.el/src/init-setup.el ~/.emacs

mkdir -p "$EMACSD/comint-history"

# rustc and cargo are for building emacs-yamlmod
# Debian GNU/Linux 10 does not have the required version of rustc
# rustc 1.41.1 will not build emacs-yaml
# rustc 1.51.0 will build it
rustc --version | grep -q " 1.5" || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

(
cd "$EMACSD/emacs-yamlmod"
source $HOME/.cargo/env
make -j 4 || :
)

# I need the tree entire tree, to get the commit I want
# So can't use --depth 1
(
cd
test -d emacs || git clone "https://github.com/emacs-mirror/emacs"
)

apt install libx11-dev
apt install libgtk2.0-dev
apt install libjpeg-dev
apt install libxpm-dev
apt install libpng-dev
apt install libpng16-16
apt install libgif-dev
apt install libtiff-dev
apt install libgnutls28-dev
apt install libjansson-dev
apt install imagemagick-6.q16 libmagick++-6-headers libmagick++-dev
apt install libgtk-3-0 libgtk-3-dev

(
    cd /root/emacs
    git checkout 0a5e9cf2622a0282d56cc150af5a94b5d5fd71be
    ./autogen.sh
    ./configure --with-all --with-x-toolkit=yes --without-makeinfo --with-modules --with-gnutls=yes
    make
    make install
)
rm -rf /root/emacs

# This is kinda optional but will give you a web-facing Pen
agi libssl-dev
pip3 install butterfly

# I want huggingface transformers and I'm going to use clojure to access them
(
cd
git clone --depth 1 "http://github.com/semiosis/huggingface-clj"
)

(
cd
git clone --depth 1 "https://github.com/syl20bnr/spacemacs"
)

apt install libreadline-dev
apt install libbsd-dev
(
cd
git clone --depth 1 "https://gitlab.com/rosie-pattern-language/rosie"
cd rosie
make
make install
)

(
cd "$EMACSD"
test -d "pen.el" || git clone --depth 1 "https://github.com/semiosis/pen.el"
)

(
cd "$EMACSD"
test -d "openai-api.el" || git clone --depth 1 "https://github.com/semiosis/openai-api.el"
)

(
cd "$EMACSD"
test -d "huggingface.el" || git clone --depth 1 "http://github.com/mullikine/huggingface.el"
)

(
cd "$EMACSD"
test -d "pen-contrib.el" || git clone --depth 1 "https://github.com/semiosis/pen-contrib.el"
)

(
export TERM=xterm
unbuffer emacs -nw --eval "(kill-emacs)"
)

(
cd
ln -sf /root/.emacs.d/pen.el/scripts/setup.sh
ln -sf /root/.emacs.d/pen.el/scripts/run.sh
)

ln -sf ~/.emacs.d/pen.el/src/init.el ~/.emacs

(
cd
git clone https://libwebsockets.org/repo/libwebsockets
cd libwebsockets && mkdir build && cd build
cmake ..
make && make install
)

(
cd
agi build-essential cmake git libjson-c-dev
git clone https://github.com/tsl0922/ttyd.git
cd ttyd && mkdir build && cd build
cmake ..
make && make install
)

