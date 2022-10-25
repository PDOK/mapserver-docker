FROM pdok/mapserver:8.0.0-new-build
LABEL maintainer="PDOK dev <https://github.com/PDOK/mapserver-docker/issues>"

USER root

RUN wget https://github.com/OSGeo/PROJ-data/releases/download/1.11.0/proj-data-1.11.tar.gz && \
    mkdir proj-data-1.11 && \
    tar xzvf proj-data-1.11.tar.gz -C /proj-data-1.11 

# RUN apt-get -y update && \
#     apt-get install -y --no-install-recommends \
#         libspatialite7 && \
#     rm -rf /var/lib/apt/lists/*

# RUN mv /proj-data-1.11/nl_nsgi_rdcorr2018.tif /usr/local/share/proj/nl_nsgi_rdcorr2018.tif && \
#     chown root:root /usr/local/share/proj/nl_nsgi_rdcorr2018.tif && \
#     mv /proj-data-1.11/nl_nsgi_nlgeo2018.tif /usr/local/share/proj/nl_nsgi_nlgeo2018.tif && \
#     chown root:root /usr/local/share/proj/nl_nsgi_nlgeo2018.tif && \
#     mv /proj-data-1.11/nl_nsgi_rdtrans2018.tif /usr/local/share/proj/nl_nsgi_rdtrans2018.tif && \
#     chown root:root /usr/local/share/proj/nl_nsgi_rdtrans2018.tif && \    
#     rm -rf proj-data-1.11*

RUN mv /proj-data-1.11/* /usr/local/share/proj/ && \
    chown -R root:root /usr/local/share/proj && \
    rm -rf proj-data-1.11*

# USER www