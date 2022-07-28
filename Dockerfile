FROM i386/alpine:edge

# Set version for s6 overlay
ARG S6_OVERLAY_VERSION=3.1.1.2
ARG S6_OVERLAY_ARCH="i686"

# Set s6 to keep environment
ENV S6_KEEP_ENV=0

# Setup environment variables
ENV HOME=/root \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=C.UTF-8 \
    DISPLAY=:0.0 \
    DISPLAY_WIDTH=1024 \
    DISPLAY_HEIGHT=768

# Install all required packages
RUN \
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk add -U --upgrade --no-cache \
    bash \
    icewm \
    shadow \
    novnc \
    wine \
    xvfb \
    x11vnc \
    xz && \
    mkdir -p /usr/share/wine/mono && wget --no-check-certificate -O - https://dl.winehq.org/wine/wine-mono/7.3.0/wine-mono-7.3.0-x86.tar.xz | tar -Jxv -C /usr/share/wine/mono && \
    mkdir -p /usr/share/wine/gecko && wget --no-check-certificate -O - http://dl.winehq.org/wine/wine-gecko/2.47.3/wine-gecko-2.47.3-x86.tar.xz | tar -Jxv -C /usr/share/wine/gecko 

# Add s6 overlay
RUN wget -O - https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch-${S6_OVERLAY_VERSION}.tar.xz | tar -C / -Jxp
RUN wget -O - https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}-${S6_OVERLAY_VERSION}.tar.xz | tar -C / -Jxp

# Setup application specific variables
ENV WINEPREFIX=/app \
    WINEDEBUG=fixme-all

RUN echo "**** create twgs user and make our folders ****" && \
    groupmod -g 1000 users && \
    useradd -u 911 -U -d /app -s /bin/false twgs && \
    usermod -G users twgs && \
    mkdir -p /app 

COPY root/ /

ENTRYPOINT ["/init"]
