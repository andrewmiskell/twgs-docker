#!/bin/ash

# Bootstrap TWGS 2.20B if not already installed
if [ ! -f "/app/.twgs_installed" ]; then
    /usr/bin/wget -O /tmp/TWGS220B.EXE http://wiki.classictw.com/filearchive/apps/TWGS220B.EXE
    /usr/bin/Xvfb :0 -screen 0 1024x768x24 &
    /usr/bin/wine /tmp/TWGS220B.EXE /s /v"/qn INSTALLDIR=C:\EIS\TWGS"
    sleep 10
    /usr/bin/pkill Xvfb
    touch "/app/.twgs_installed"
    /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
else
    /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf 
fi

