# ERTS89andRDNAP test

This is to test if RDNAPTRANS transformations are used properly.
The test source data originates from NSGI.

TODO automate this test in the build

## Run mapserver

### existing 7.6.4-patch5-2-buster-lighttpd

serving etrs89 source

```docker
docker run --rm -d -p 80:80 --name etrs89 -v `pwd`/ETRS89andRDNAP:/srv/data -e DEBUG=0 -e MIN_PROCS=1 -e MAX_PROCS=3 -e MAX_LOAD_PER_PROC=4 -e IDLE_TIMEOUT=20 -e MS_MAPFILE=/srv/data/etrs89.map pdok/mapserver:7.6.4-patch5-2-buster-lighttpd
```

serving rd source

```docker
docker run --rm -p 80:80 --name rdnap -v `pwd`/ETRS89andRDNAP:/srv/data -e DEBUG=0 -e MIN_PROCS=1 -e MAX_PROCS=3 -e MAX_LOAD_PER_PROC=4 -e IDLE_TIMEOUT=20    -e MS_MAPFILE=/srv/data/rd.map pdok/mapserver:7.6.4-patch5-2-buster-lighttpd-nl
```

### local built 8

```docker
docker build --target NL -t pdok/mapserver:8-local-NL .
```

serving etrs89 source

```docker
docker run --rm -p 80:80 --name etrs89-new -v `pwd`/ETRS89andRDNAP:/srv/data:rw -e DEBUG=0 -e MAPSERVER_CONFIG_FILE=/srv/data/etrs89.conf -e SERVICE_TYPE=wfs -e MS_MAPFILE=/srv/data/etrs89.map pdok/mapserver:8-local-NL
```

serving rd source

```docker
docker run --rm -p 80:80 --name rdnap-new -v `pwd`/ETRS89andRDNAP:/srv/data -e DEBUG=0 -e MIN_PROCS=1 -e MAX_PROCS=3 -e MAX_LOAD_PER_PROC=4 -e IDLE_TIMEOUT=20 -e MAPSERVER_CONFIG_FILE=/srv/data/rd.conf -e MS_MAPFILE=/srv/data/rd.map pdok/mapserver:8.0.0-lighttpd-nl
```

## Verify the output

reverse below env vars when serving rd

```shell
SOURCE_NAME=etrs89 && \
OUT_NAME=rd && \
OUT_EPSG=28992 && \
curl -sS "localhost/mapserver?service=WFS&version=2.0.0&request=GetFeature&count=100&typeName=$SOURCE_NAME&outputFormat=geojson&srsName=EPSG:$OUT_EPSG" | \
 jq --arg crs $OUT_NAME '.features | .[] | { id, x_dev: (.geometry.coordinates[0] - (.properties[$crs+"_x"]|tonumber)), y_dev: (.geometry.coordinates[1] - (.properties[$crs+"_y"]|tonumber)) } | {error: ((.x_dev|abs) > 0.001 or (.y_dev|abs) > 0.001 )} + .'
```
