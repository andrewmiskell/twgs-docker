#!/bin/bash
# Checks for the listening socket without connecting: a connection would take
# up the only player node on an unregistered server.
port=$(awk '/Trade Wars 2002 Game Server\\\\Configuration\]/ {found=1; next}
            /^\[/ {found=0}
            found && /^"Port"=/ {gsub(/[^0-9]/, ""); print; exit}' /data/wine/system.reg)
ss -lnt | grep -q ":${port:-2002} "
