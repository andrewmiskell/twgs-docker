FROM i386/alpine:edge

# Install all required packages
RUN \
    # Install required packages
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk add --update --upgrade \
    bash \
    icewm \
    shadow \
    supervisor \
    novnc \
    wine \
    xvfb \
    x11vnc \
    xz && \
    mkdir -p /usr/share/wine/mono && wget --no-check-certificate -O - https://dl.winehq.org/wine/wine-mono/7.3.0/wine-mono-7.3.0-x86.tar.xz | tar -Jxv -C /usr/share/wine/mono && \
    mkdir -p /usr/share/wine/gecko && wget --no-check-certificate -O - http://dl.winehq.org/wine/wine-gecko/2.47.3/wine-gecko-2.47.3-x86.tar.xz | tar -Jxv -C /usr/share/wine/gecko 

# Setup environment variables
ENV HOME=/root \
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

ENTRYPOINT ["/usr/bin/entrypoint"]
