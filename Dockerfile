FROM debian:bookworm AS builder
LABEL maintainer="PDOK dev <https://github.com/PDOK/mapserver-docker/issues>"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Amsterdam

RUN apt-get update -y --fix-missing && \
    apt-get install -y --no-install-recommends --fix-missing \
        ca-certificates \
        gettext \
        xz-utils \
        cmake \
        gcc \
        g++ \
        libcurl4-gnutls-dev \
        libexempi-dev \
        libfcgi-dev \
        libfreetype6-dev \
        libfribidi-dev \
        libgeos-dev \
        libgif-dev \
        libglib2.0-dev \
        libcairo2-dev \
        sqlite3 \
        libjpeg-dev \
        libpng-dev \
        libpq-dev \
        libprotobuf-c-dev \
        libprotobuf-c1 \
        libprotobuf-dev \
        libprotobuf32 \
        librsvg2-dev \
        libsqlite3-dev \
        libtiff5-dev \
        libxslt1-dev \
        git \
        locales \
        make \
        patch \
        openssh-server \
        protobuf-compiler \
        protobuf-c-compiler \
        software-properties-common \
        wget \
        && \
    rm -rf /var/lib/apt/lists/*

RUN update-locale LANG=C.UTF-8

ENV HARFBUZZ_VERSION="7.3.0"
RUN cd /tmp && \
        wget https://github.com/harfbuzz/harfbuzz/releases/download/$HARFBUZZ_VERSION/harfbuzz-$HARFBUZZ_VERSION.tar.xz && \
        tar xJf harfbuzz-$HARFBUZZ_VERSION.tar.xz && \
        cd harfbuzz-$HARFBUZZ_VERSION && \
        ./configure && \
        make && \
        make install && \
        ldconfig

ENV PROJ_VERSION="9.3.1"
RUN wget https://github.com/OSGeo/PROJ/releases/download/${PROJ_VERSION}/proj-${PROJ_VERSION}.tar.gz
RUN tar xzvf proj-${PROJ_VERSION}.tar.gz && \
    cd /proj-${PROJ_VERSION} && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF && make -j$(nproc) && make install

ENV GDAL_VERSION="3.9.2"
RUN wget https://github.com/OSGeo/gdal/releases/download/v${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz
RUN tar xzvf gdal-${GDAL_VERSION}.tar.gz && \
    cd /gdal-${GDAL_VERSION} && \
    mkdir build && \
    cd build && \
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTING=OFF \
        && \
    cmake --build . && \
    cmake --build . --target install

ENV MAPSERVER_VERSION="8.2.2"
RUN mkdir /usr/local/src/mapserver
RUN wget https://github.com/MapServer/MapServer/releases/download/rel-$(echo $MAPSERVER_VERSION | sed -e "s/\./-/g")/mapserver-${MAPSERVER_VERSION}.tar.gz
RUN tar -xf mapserver-8.*.tar.gz --strip-components 1  -C /usr/local/src/mapserver
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
        && \
    make && \
    make install && \
    ldconfig

# pre-release image lighttpd build from https://github.com/PDOK/lighttpd-docker/tree/PDOK-14748_mapserver_8
# TODO use definitive lighttpd image
FROM pdok/lighttpd:1.4.67-bookworm-rc1 AS service

USER root
LABEL maintainer="PDOK dev <https://github.com/PDOK/mapserver-docker/issues>"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Amsterdam

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
        wget \
        sqlite3 \
        gnupg \
        && \
    rm -rf /var/lib/apt/lists/*
RUN apt-get clean

# Mirror the PROJ.org Datumgrid CDN.
WORKDIR /usr/local/share/proj
RUN wget --no-verbose -e robots=off --content-on-error --mirror https://cdn.proj.org/ || [ $? -eq 8 ]
RUN cd cdn.proj.org && rm -fv *.js *.css *.html favicon* && mv * .. && cd .. && rmdir cdn.proj.org
WORKDIR /

COPY --from=builder  /usr/local/share/proj/ /usr/local/share/proj/
COPY --from=builder /usr/include/ /usr/include/
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/lib/ /usr/local/lib/
RUN chmod o+x /usr/local/bin/mapserv

ADD config/lighttpd.conf /srv/mapserver/config/lighttpd.conf
ADD config/include.conf /srv/mapserver/config/include.conf
ADD config/request.lua /srv/mapserver/config/request.lua

USER www

ENV DEBUG=0
ENV MIN_PROCS=8
ENV MAX_PROCS=8
ENV MAX_LOAD_PER_PROC=1
ENV IDLE_TIMEOUT=20

EXPOSE 80

CMD ["lighttpd", "-D", "-f", "/srv/mapserver/config/lighttpd.conf"]

FROM ghcr.io/geodetischeinfrastructuur/transformations:1.2.1 AS nsgi-transformations
FROM service AS NL

USER root

# from https://github.com/GeodetischeInfrastructuur/transformations/blob/main/Dockerfile
# not copying proj.db but applying the same additions
COPY --from=nsgi-transformations \
    /usr/share/proj/bq_nsgi_bongeo2004.tif \
    /usr/share/proj/nllat2018.gtx \
    /usr/local/share/proj/
COPY --from=nsgi-transformations /usr/share/proj/nl_nsgi_sql /usr/local/share/proj/nl_nsgi_sql
RUN cat /usr/local/share/proj/nl_nsgi_sql/nl_nsgi_00_authorities.sql | sqlite3 /usr/local/share/proj/proj.db
RUN cat /usr/local/share/proj/nl_nsgi_sql/nl_nsgi_10_copy_transformations_from_projdb.sql | sqlite3 /usr/local/share/proj/proj.db
RUN cat /usr/local/share/proj/nl_nsgi_sql/nl_nsgi_20_datum_and_crs.sql | sqlite3 /usr/local/share/proj/proj.db
RUN cat /usr/local/share/proj/nl_nsgi_sql/nl_nsgi_30_local_transformations.sql | sqlite3 /usr/local/share/proj/proj.db
RUN cat /usr/local/share/proj/nl_nsgi_sql/nl_nsgi_40_regional_transformations.sql | sqlite3 /usr/local/share/proj/proj.db
RUN cat /usr/local/share/proj/nl_nsgi_sql/nl_nsgi_50_wgs84_null_transformations.sql | sqlite3 /usr/local/share/proj/proj.db

USER www

FROM service AS default
