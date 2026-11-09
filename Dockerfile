# Contains Wine and the web UI only. TWGS itself is installed at runtime from
# installers you supply, so this image holds no TWGS code.
FROM debian:trixie-slim

RUN dpkg --add-architecture i386 \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      wine wine32 \
      xvfb openbox x11vnc xdotool wmctrl \
      novnc websockify \
      p7zip-full procps iproute2 tini tzdata \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 twgs \
 && install -d -o twgs -g twgs /data \
 && install -d -m 1777 /tmp/.X11-unix \
 && printf '<meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=1&resize=scale">\n' > /usr/share/novnc/index.html

COPY entrypoint.sh twgs-backup healthcheck.sh /usr/local/bin/

ENV TWGS_VERSION=220B
VOLUME /data

# 2002 players (telnet), 2003 TWGS remote admin (telnet), 6080 web UI (noVNC)
EXPOSE 2002 2003 6080

# Long start period: the first start initialises Wine and runs the installer.
HEALTHCHECK --interval=30s --timeout=5s --start-period=3m --retries=3 CMD ["healthcheck.sh"]

ENTRYPOINT ["tini", "--", "entrypoint.sh"]
