FROM ubuntu:22.04 as builder
LABEL maintainer="PDOK dev <https://github.com/PDOK/mapserver-docker/issues>"

ENV DEBIAN_FRONTEND noninteractive
ENV TZ Europe/Amsterdam

RUN apt-get -y update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    gettext \
    xz-utils \
    cmake \
    ninja-build \
    gcc \
    g++ \
    libfreetype6-dev \
    libglib2.0-dev \
    libcairo2-dev \
    git \
    locales \
    make \
    patch \
    openssh-server \
    protobuf-compiler \
    protobuf-c-compiler \
    software-properties-common \
    wget && \
    rm -rf /var/lib/apt/lists/*

RUN update-locale LANG=C.UTF-8

ENV HARFBUZZ_VERSION 2.8.2

RUN cd /tmp && \
    wget https://github.com/harfbuzz/harfbuzz/releases/download/$HARFBUZZ_VERSION/harfbuzz-$HARFBUZZ_VERSION.tar.xz && \
    tar xJf harfbuzz-$HARFBUZZ_VERSION.tar.xz && \
    cd harfbuzz-$HARFBUZZ_VERSION && \
    ./configure && \
    make && \
    make install && \
    ldconfig

RUN apt-get -y update && \
    apt-get install -y --no-install-recommends \
    libcurl4-gnutls-dev \
    libfribidi-dev \
    libgif-dev \
    libjpeg-dev \
    libpq-dev \
    librsvg2-dev \
    libpng-dev \
    libfreetype6-dev \
    libjpeg-dev \
    libexempi-dev \
    libfcgi-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    librsvg2-dev \
    libprotobuf-dev \
    libprotobuf-c-dev \
    libprotobuf-c1 \
    libxslt1-dev && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get -y update --fix-missing


ARG MAPSERVER_BRANCH=branch-8-0
ARG MAPSERVER_REPO=https://github.com/mapserver/mapserver

RUN git clone --single-branch -b ${MAPSERVER_BRANCH} ${MAPSERVER_REPO} /usr/local/src/mapserver

RUN mkdir /usr/local/src/mapserver/build && \
    cd /usr/local/src/mapserver/build && \
    cmake ../ \
    -GNinja \
    -DWITH_PROTOBUFC=ON \
    -DWITH_KML=OFF \
    -DWITH_SOS=OFF \
    -DWITH_WMS=ON \
    -DWITH_FRIBIDI=ON \
    -DWITH_HARFBUZZ=ON \
    -DWITH_ICONV=ON \
    -DWITH_CAIRO=ON \
    -DWITH_SVGCAIRO=OFF \
    -DWITH_RSVG=ON \
    -DWITH_MYSQL=OFF \
    -DWITH_FCGI=ON \
    -DWITH_GEOS=ON \
    -DWITH_POSTGIS=ON \
    -DWITH_CLIENT_WMS=ON \
    -DWITH_CLIENT_WFS=ON \
    -DWITH_CURL=ON \
    -DWITH_WFS=ON \
    -DWITH_WCS=ON \
    -DWITH_OGCAPI=OFF \
    -DWITH_LIBXML2=ON \
    -DWITH_THREAD_SAFETY=OFF \
    -DWITH_GIF=ON \
    -DWITH_PYTHON=OFF \
    -DWITH_PHP=OFF \
    -DWITH_PERL=OFF \
    -DWITH_RUBY=OFF \
    -DWITH_JAVA=OFF \
    -DWITH_CSHARP=OFF \
    -DWITH_ORACLESPATIAL=OFF \
    -DWITH_ORACLE_PLUGIN=OFF \
    -DWITH_MSSQL2008=OFF \    
    -DWITH_EXEMPI=ON \
    -DWITH_XMLMAPFILE=ON \
    -DWITH_V8=OFF \
    -DWITH_PIXMAN=OFF \
    -DBUILD_STATIC=OFF \
    -DLINK_STATIC_LIBMAPSERVER=OFF \
    -DWITH_APACHE_MODULE=OFF \
    -DWITH_GENERIC_NINT=OFF \
    -DWITH_PYMAPSCRIPT_ANNOTATIONS=OFF \
    -DFUZZER=OFF \
    -DCMAKE_PREFIX_PATH=/opt/gdal && \
    ninja install 

FROM pdok/lighttpd:1.4.65-ubuntu-22-04 as service
LABEL maintainer="PDOK dev <https://github.com/PDOK/mapserver-docker/issues>"

ENV DEBIAN_FRONTEND noninteractive
ENV TZ Europe/Amsterdam

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib /usr/local/lib
USER root
RUN apt-get -y update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    libpng16-16 \
    python-cairocffi-doc \
    libfreetype6 \
    libfcgi0ldbl \
    libfribidi0 \
    libgdal30 \
    libgeos-c1v5 \
    libglib2.0-0 \
    libproj22 \
    libxml2 \
    libxslt1.1 \
    libexempi8 \
    libpq5 \
    libfreetype6 \
    librsvg2-2 \
    libprotobuf23 \
    libprotobuf-c1 \
    gettext-base \
    wget \
    gnupg && \
    rm -rf /var/lib/apt/lists/*

COPY etc/lighttpd.conf /lighttpd.conf
COPY etc/filter-map.lua /filter-map.lua
COPY etc/mapserver.conf /mapserver.conf

RUN chmod o+x /usr/local/bin/mapserv
RUN apt-get clean

USER www

ENV DEBUG 0
ENV MIN_PROCS 1
ENV MAX_PROCS 3
ENV MAX_LOAD_PER_PROC 4
ENV IDLE_TIMEOUT 20
ENV MAPSERVER_CONFIG_FILE /mapserver.conf

EXPOSE 80

CMD ["lighttpd", "-D", "-f", "/lighttpd.conf"]
