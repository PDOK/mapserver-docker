FROM pdok/mapserver:7.6.4-patch-5-5
LABEL maintainer="PDOK dev <https://github.com/PDOK/mapserver-docker/issues>"
USER root
RUN wget https://github.com/OSGeo/proj-datumgrid/releases/download/europe-1.6/proj-datumgrid-europe-1.6.tar.gz && \
    mkdir proj-datumgrid-europe-1.6 && \
    tar xzvf proj-datumgrid-europe-1.6.tar.gz -C /proj-datumgrid-europe-1.6 && \
    mv /proj-datumgrid-europe-1.6/rdtrans2018.gsb /usr/share/proj/rdtrans2018.gsb && \
    mv /proj-datumgrid-europe-1.6/naptrans2018.gtx /usr/share/proj/naptrans2018.gtx && \
    rm -rf proj-datumgrid*

COPY nl/epsg /usr/share/proj
USER www