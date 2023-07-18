FROM debian:bookworm as builder
LABEL maintainer="PDOK dev <https://github.com/PDOK/mapserver-docker/issues>"

ENV DEBIAN_FRONTEND noninteractive
ENV TZ Europe/Amsterdam

RUN apt-get -y update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        gettext \
        xz-utils \
        cmake \
        gcc \
        g++ \
        libfreetype6-dev \
        libglib2.0-dev \
        libcairo2-dev \
        sqlite3 \
        libsqlite3-dev \
        libtiff5-dev \
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

ENV HARFBUZZ_VERSION 7.3.0

RUN cd /tmp && \
        wget https://github.com/harfbuzz/harfbuzz/releases/download/$HARFBUZZ_VERSION/harfbuzz-$HARFBUZZ_VERSION.tar.xz && \
        tar xJf harfbuzz-$HARFBUZZ_VERSION.tar.xz && \
        cd harfbuzz-$HARFBUZZ_VERSION && \
        ./configure && \
        make && \
        make install && \
        ldconfig

ENV PROJ_VERSION="9.2.0"

RUN wget https://github.com/OSGeo/PROJ/releases/download/${PROJ_VERSION}/proj-${PROJ_VERSION}.tar.gz

RUN apt-get -y update && \
    apt-get install -y --no-install-recommends \
        libcurl4-gnutls-dev && \
    rm -rf /var/lib/apt/lists/*

# Build proj
RUN tar xzvf proj-${PROJ_VERSION}.tar.gz && \
    cd /proj-${PROJ_VERSION} && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF && make -j$(nproc) && make install


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
        librsvg2-dev \
        libprotobuf-dev \
        libprotobuf-c-dev \
        libprotobuf-c1 \
        libprotobuf32 \
        libxslt1-dev && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get -y update --fix-missing

RUN git clone -b branch-8-0 https://github.com/MapServer/mapserver.git /usr/local/src/mapserver

RUN mkdir /usr/local/src/mapserver/build && \
    cd /usr/local/src/mapserver/build && \
    cmake ../ \
        -DWITH_PROJ=ON \
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
        -DWITH_GDAL=ON \
        -DWITH_OGR=ON \
        -DWITH_CURL=ON \
        -DWITH_CLIENT_WMS=ON \
        -DWITH_CLIENT_WFS=ON \
        -DWITH_WFS=ON \
        -DWITH_WCS=ON \
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
        -DWITH_SDE_PLUGIN=OFF \
        -DWITH_SDE=OFF \
        -DWITH_EXEMPI=ON \
        -DWITH_XMLMAPFILE=ON \
        -DWITH_V8=OFF \
        -DBUILD_STATIC=OFF \
        -DLINK_STATIC_LIBMAPSERVER=OFF \
        -DWITH_APACHE_MODULE=OFF \
        -DWITH_POINT_Z_M=ON \
        -DWITH_GENERIC_NINT=OFF \
        -DWITH_PROTOBUFC=ON \
        -DCMAKE_PREFIX_PATH=/opt/gdal && \
    make && \
    make install && \
    ldconfig

#local image lighttpd build from https://github.com/PDOK/lighttpd-docker/tree/PDOK-14748_mapserver_8
FROM lighttpd:1 AS service

USER root
LABEL maintainer="PDOK dev <https://github.com/PDOK/mapserver-docker/issues>"

ENV DEBIAN_FRONTEND noninteractive
ENV TZ Europe/Amsterdam

COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/local/share/proj /usr/local/share/proj

RUN apt-get -y update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        libpng16-16 \
        python-cairocffi-doc \
        libfreetype6 \
        libgif7 \
        libjpeg62-turbo \
        libfcgi0ldbl \
        libfribidi0 \
        libgdal32 \
        libgeos-c1v5 \
        libglib2.0-0 \
        libxml2 \
        libxslt1.1 \
        libexempi8 \
        libpq5 \
        libcurl3-gnutls \
        libfreetype6 \
        librsvg2-2 \
        libprotobuf32 \
        libprotobuf-c1 \
        gettext-base \
        libsqlite3-mod-spatialite \
        gdal-bin \
        wget \
        gnupg && \
    rm -rf /var/lib/apt/lists/*

ADD config/lighttpd.conf /srv/mapserver/config/lighttpd.conf
ADD config/include.conf /srv/mapserver/config/include.conf
ADD config/request.lua /srv/mapserver/config/request.lua

RUN chmod o+x /usr/local/bin/mapserv
RUN apt-get clean
USER www

ENV DEBUG 0
ENV MIN_PROCS 4
ENV MAX_PROCS 8
ENV MAX_LOAD_PER_PROC 1
ENV IDLE_TIMEOUT 20

EXPOSE 80

CMD ["lighttpd", "-D", "-f", "/srv/mapserver/config/lighttpd.conf"]
