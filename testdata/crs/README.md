# ERTS89andRDNAP test

This tests projecting WFS features in different coordinate systems, in particular:
- EPSG:3034
- EPSG:3035
- EPSG:4258
- EPSG:4326
- CRS:84

TODO automate this test in the build

## Run mapserver

### existing 7.6.4-patch5-2-buster-lighttpd

serving etrs89 source

```docker
docker run --rm -p 80:80 -v `pwd`/testdata/crs:/srv/data -e MAPSERVER_CONFIG_FILE=/srv/data/natpark.conf -e SERVICE_TYPE=wfs -e MS_MAPFILE=/srv/data/natpark.map pdok/mapserver:7.6.4-patch5-2-buster-lighttpd

```

### local built 8

Warning: This docker build compiles dependencies and will take a long time when running for the first time
```docker
docker build --target NL -t pdok/mapserver:8-local-NL .
```

serving natpark source

```docker
docker run --rm -p 80:80 -v `pwd`/testdata/crs:/srv/data -e MAPSERVER_CONFIG_FILE=/srv/data/natpark.conf -e SERVICE_TYPE=wfs -e MS_MAPFILE=/srv/data/natpark.map pdok/mapserver:8-local-NL
```

## Verify the output


```shell
IMAGE=pdok/mapserver:8-local-NL && \
SOURCE_NAME=rd && \
OUT_NAME=etrs89 && \
OUT_EPSG=4258 && \
docker run --rm -p 80:80 -v `pwd`/ETRS89andRDNAP:/srv/data \
  -e MAPSERVER_CONFIG_FILE=/srv/data/${SOURCE_NAME}.conf -e SERVICE_TYPE=wfs -e MS_MAPFILE=/srv/data/${SOURCE_NAME}.map --entrypoint=mapserv \
  "${IMAGE}" \
  -nh "QUERY_STRING=service=WFS&version=2.0.0&request=GetFeature&typeName=${SOURCE_NAME}&outputFormat=geojson&srsName=EPSG:${OUT_EPSG}" | \
 jq --arg crs "${OUT_NAME}" '.features | .[] | { id, x_dev: (.geometry.coordinates[0] - (.properties[$crs+"_x"]|tonumber)), y_dev: (.geometry.coordinates[1] - (.properties[$crs+"_y"]|tonumber)) } | {error: ((.x_dev|abs) > 0.001 or (.y_dev|abs) > 0.001 )} + .' | \
 jq -s 'group_by (.error)[] | {error: .[0].error, count: length}'
```
