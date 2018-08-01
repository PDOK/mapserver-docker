FROM debian:stretch as builder
MAINTAINER PDOK dev <pdok@kadaster.nl>

ENV DEBIAN_FRONTEND noninteractive
ENV TZ Europe/Amsterdam

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        gettext \
        bzip2 \
        cmake \
        g++ \
        git \
        libcairo2-dev \
        locales \
        make \
        openssh-server \
        software-properties-common \
        wget && \
    rm -rf /var/lib/apt/lists/*

RUN update-locale LANG=C.UTF-8

ENV HARFBUZZ_VERSION 1.2.4

RUN cd /tmp && \
        wget https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-$HARFBUZZ_VERSION.tar.bz2 && \
        tar xjf harfbuzz-$HARFBUZZ_VERSION.tar.bz2 && \
        cd harfbuzz-$HARFBUZZ_VERSION && \
        ./configure && \
        make && \
        make install && \
        ldconfig

RUN apt-get update && \
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
        libxslt1-dev && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --single-branch -b branch-7-2 https://github.com/mapserver/mapserver/ /usr/local/src/mapserver

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
        -DWITH_RSVG=OFF \
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
        -DWITH_GENERIC_NINT=OFF \
        -DWITH_USE_POINT_Z_M=ON \
        -DWITH_PROTOBUFC=OFF \
        -DCMAKE_PREFIX_PATH=/opt/gdal && \
    make && \
    make install && \
    ldconfig

FROM debian:stretch as service
MAINTAINER PDOK dev <pdok@kadaster.nl>

ENV DEBIAN_FRONTEND noninteractive
ENV TZ Europe/Amsterdam

COPY --from=0 /usr/local/bin /usr/local/bin
COPY --from=0 /usr/local/lib /usr/local/lib

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        fonts-liberation2 \
        libcairo2-dev \
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
        libxslt1-dev && \
    rm -rf /var/lib/apt/lists/*

COPY etc/epsg /usr/share/proj

RUN chmod o+x /usr/local/bin/mapserv

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    nginx \
    supervisor \
    spawn-fcgi && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get clean

RUN mkdir -p /var/log/supervisor

COPY etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY etc/nginx.conf /etc/nginx/sites-available/default

EXPOSE 80

WORKDIR /etc/nginx

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
