FROM i386/alpine:edge

# Install all required packages
RUN \
    # Install required packages
    sed -i 's/dl-cdn/dl-3/g' /etc/apk/repositories && \
    echo "https://dl-3.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk --update --upgrade --no-cache add \
      bash \
      icewm \
      novnc \
      shadow \
      wine \
      xvfb \
      x11vnc \
      xz && \
    mkdir -p /usr/share/wine/mono && wget -O - https://dl.winehq.org/wine/wine-mono/7.0.0/wine-mono-7.0.0-x86.tar.xz | tar -Jxv -C /usr/share/wine/mono && \
    mkdir -p /usr/share/wine/gecko && wget -O - http://dl.winehq.org/wine/wine-gecko/2.47.2/wine-gecko-2.47.2-x86.tar.xz | tar -Jxv -C /usr/share/wine/gecko 

# Set version for s6 overlay
ARG S6_OVERLAY_VERSION=3.0.0.2
ARG S6_OVERLAY_ARCH="i686"

# Set s6 to keep environment
ENV S6_KEEP_ENV=0

# Add s6 overlay
RUN wget -O - https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch-${S6_OVERLAY_VERSION}.tar.xz | tar -C / -Jxp
RUN wget -O - https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}-${S6_OVERLAY_VERSION}.tar.xz | tar -C / -Jxp

# Setup environment variables
ENV HOME=/root \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=C.UTF-8 \
    DISPLAY=:0.0 \
    DISPLAY_WIDTH=1024 \
    DISPLAY_HEIGHT=768

# Setup application specific variables
ENV WINEPREFIX=/app \
    WINEDEBUG=fixme-all

RUN echo "**** create abc user and make our folders ****" && \
 groupmod -g 1000 users && \
 useradd -u 911 -U -d /config -s /bin/false abc && \
 usermod -G users abc && \
 mkdir -p \
 /app \
 /config

COPY root/ /
 
ENTRYPOINT ["/init"]
