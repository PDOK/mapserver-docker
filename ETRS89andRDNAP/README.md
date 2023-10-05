# ERTS89andRDNAP

## 7.6.4-patch5-2-buster-lighttpd

```docker
docker run --rm -d -p 80:80 --name etrs89 -v `pwd`/ETRS89andRDNAP:/srv/data -e DEBUG=0 -e MIN_PROCS=1 -e MAX_PROCS=3 -e MAX_LOAD_PER_PROC=4 -e IDLE_TIMEOUT=20 -e MS_MAPFILE=/srv/data/etrs89.map pdok/mapserver:7.6.4-patch5-2-buster-lighttpd
```

```docker
docker run --rm -p 80:80 --name rdnap -v `pwd`/ETRS89andRDNAP:/srv/data -e DEBUG=0 -e MIN_PROCS=1 -e MAX_PROCS=3 -e MAX_LOAD_PER_PROC=4 -e IDLE_TIMEOUT=20    -e MS_MAPFILE=/srv/data/rdnap.map pdok/mapserver:7.6.4-patch5-2-buster-lighttpd-nl
```

## 8.0.0-lighttpd

```docker
docker build -f Dockerfile.NL -t pdok/mapserver:8.0.0-lighttpd-nl .
```

```docker
docker run --rm -p 80:80 --name etrs89-new -v `pwd`/ETRS89andRDNAP:/srv/data:rw -e DEBUG=0 -e MAPSERVER_CONFIG_FILE=/srv/data/etrs89.conf -e SERVICE_TYPE=wfs -e MS_MAPFILE=/srv/data/etrs89.map pdok/mapserver:8.0-nl
```

```docker
docker run --rm -p 80:80 --name rdnap-new -v `pwd`/ETRS89andRDNAP:/srv/data -e DEBUG=0 -e MIN_PROCS=1 -e MAX_PROCS=3 -e MAX_LOAD_PER_PROC=4 -e IDLE_TIMEOUT=20 -e MAPSERVER_CONFIG_FILE=/srv/data/rd.conf -e MS_MAPFILE=/srv/data/rdnap.map pdok/mapserver:8.0.0-lighttpd-nl
```
