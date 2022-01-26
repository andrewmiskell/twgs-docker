FROM i386/alpine:edge

# Install all required packages
RUN \
    # Install required packages
    sed -i 's/dl-cdn/dl-3/g' /etc/apk/repositories && \
    echo "https://dl-3.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk --update --upgrade add \
      bash \
      fluxbox \
      supervisor \
      novnc \
      wine \
      xvfb \
      x11vnc \
      xz && \
    mkdir -p /usr/share/wine/mono && wget -O - https://dl.winehq.org/wine/wine-mono/7.0.0/wine-mono-7.0.0-x86.tar.xz | tar -Jxv -C /usr/share/wine/mono && \
    mkdir -p /usr/share/wine/gecko && wget -O - http://dl.winehq.org/wine/wine-gecko/2.47.2/wine-gecko-2.47.2-x86_64.tar.xz | tar -Jxv -C /usr/share/wine/gecko 

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
ENV WINEPREFIX=/app

RUN mkdir -p /app

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY --chmod=755 entrypoint.sh /usr/bin/entrypoint

ENTRYPOINT ["/usr/bin/entrypoint"]
