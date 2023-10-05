FROM pdok/mapserver:8.0
LABEL maintainer="PDOK dev <https://github.com/PDOK/mapserver-docker/issues>"
USER root
RUN wget https://github.com/OSGeo/PROJ-data/releases/download/1.15.0/proj-data-1.15.tar.gz

RUN mkdir proj-data-1.15 && \
    tar xzvf proj-data-1.15.tar.gz -C /proj-data-1.15 && \
    cp /proj-data-1.15/*.* /usr/share/proj/ && \
    cp /proj-data-1.15/*.* /usr/local/share/proj/ && \
    rm -rf proj-datumgrid*

COPY --from=nsgi/proj:9.3.0 /usr/share/proj/proj.db /usr/local/share/proj/proj.db
COPY --from=nsgi/proj:9.3.0 /usr/share/proj/proj.db /usr/share/proj/proj.db

COPY ./null /usr/share/proj/null
COPY ./null /usr/local/share/proj/null


RUN chown root root /usr/local/share/proj/*
RUN chown root root /usr/share/proj/*

# /usr/local/share/proj
USER www