# ERTS89andRDNAP test

This tests projecting WFS features in different coordinate systems, in particular:
- EPSG:3034
- EPSG:3035
- EPSG:4258
- EPSG:4326
- CRS:84

This dataset has only 1 feature to have a reduced size in the Git repository.

## Run mapserver

### existing 7.6.4-patch5-2-buster-lighttpd

```docker
docker run --rm -p 80:80 -v `pwd`/testdata/crs:/srv/data -e MAPSERVER_CONFIG_FILE=/srv/data/natpark.conf -e SERVICE_TYPE=wfs -e MS_MAPFILE=/srv/data/natpark.map pdok/mapserver:7.6.4-patch5-2-buster-lighttpd

```

The server then can be contact at `http://localhost:80/mapserver?request=GetCapabilities&service=WFS`

### local built 8

Warning: This docker build compiles dependencies and will take a long time when running for the first time
```docker
docker build --target NL -t pdok/mapserver:8-local-NL .
```

Serving Nationale Parken source

```docker
docker run --rm -p 80:80 -v `pwd`/testdata/crs:/srv/data -e MAPSERVER_CONFIG_FILE=/srv/data/natpark.conf -e SERVICE_TYPE=wfs -e MS_MAPFILE=/srv/data/natpark.map pdok/mapserver:8-local-NL
```

The server then can be contact at `http://localhost:80/mapserver?request=GetCapabilities&service=WFS`

## Verify the output


```shell
exit_code=0
mkdir -p `pwd`/testdata/crs/actual/;
IMAGE=pdok/mapserver:8-local-NL && \
SOURCE_NAME=natpark && \
OUT_NAME=etrs89 && \
OUT_EPSG=4258 && \
docker run --rm -p 80:80 -v `pwd`/testdata/crs:/srv/data -e MAPSERVER_CONFIG_FILE=/srv/data/natpark.conf -e SERVICE_TYPE=wfs -e MS_MAPFILE=/srv/data/natpark.map --entrypoint=mapserv \
  "${IMAGE}" \
  -nh "QUERY_STRING=service=WFS&request=GetFeature&count=1&version=2.0.0&outputFormat=application/json&typeName=nationaleparken&srsName=EPSG:${OUT_EPSG}" > `pwd`/testdata/crs/actual/output.json;
[ $(cat `pwd`/testdata/crs/actual/output.json | jq -r '.crs.properties.name') == "urn:ogc:def:crs:EPSG::4258" ] || exit_code=1;
[ $(cat `pwd`/testdata/crs/actual/output.json | jq -r '.bbox[0]' | xargs -I '{}' echo "scale=5;" "({}-4.3646379084)/1 == 0" | bc) ] || exit_code=1;
[ $(cat `pwd`/testdata/crs/actual/output.json | jq -r '.bbox[1]' | xargs -I '{}' echo "scale=5;" "({}-51.3620482342678)/1 == 0" | bc) ] || exit_code=1;
[ $(cat `pwd`/testdata/crs/actual/output.json | jq -r '.bbox[2]' | xargs -I '{}' echo "scale=5;" "({}-4.46528581228022)/1 == 0" | bc) ] || exit_code=1;
[ $(cat `pwd`/testdata/crs/actual/output.json | jq -r '.bbox[3]' | xargs -I '{}' echo "scale=5;" "({}-51.4268875774673)/1 == 0" | bc) ] || exit_code=1;
echo $exit_code
```
