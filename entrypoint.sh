#!/bin/ash

# Bootstrap TWGS 2.20B if not already installed
if [ ! -f "/app/.twgs_installed" ]; then
    /usr/bin/wget -O /tmp/TWGS220B.EXE http://wiki.classictw.com/filearchive/apps/TWGS220B.EXE
    /usr/bin/wine /tmp/TWGS220B.EXE /s /v"/qn INSTALLDIR=C:\EIS\TWGS"
    touch "/app/.twgs_installed"
    echo "TWGS Installed!"
else
    echo "TWGS Installation Detected! Proceeding to startup!"
fi

