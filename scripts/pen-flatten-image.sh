#!/bin/bash
export TTY

cd
pwd
docker export pen -o pen.tar
if test -f "pen.tar"; then
    :
fi
cat pen.tar | docker import - semiosis/pen.el