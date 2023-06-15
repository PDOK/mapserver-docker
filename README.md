# Mapserver docker

[![GitHub
license](https://img.shields.io/github/license/PDOK/mapserver-docker)](https://github.com/PDOK/mapserver-docker/blob/master/LICENSE)
[![GitHub
release](https://img.shields.io/github/release/PDOK/mapserver-docker.svg)](https://github.com/PDOK/mapserver-docker/releases)
[![Docker
Pulls](https://img.shields.io/docker/pulls/pdok/mapserver.svg)](https://hub.docker.com/r/pdok/mapserver)

[Mapserver](https://mapserver.org/) [Docker](https://www.docker.com/) image
using [lighttpd](https://www.lighttpd.net/) build with
[GDAL/OGR](https://gdal.org/), [PostGIS](https://postgis.net/) to serve out WMS,
WFS and WCS services.

## TL;DR

### docker build

```shell
docker build -t pdok/mapserver .
```

### docker run wms

```shell
docker run -e MAPSERVER_CONFIG_FILE=/srv/data/example.conf -e MS_MAPFILE=/srv/data/example.map -e SERVICE_TYPE=WMS --rm -d \
            -p 80:80 --name mapserver-example -v `pwd`/example:/srv/data pdok/mapserver
```

### docker run wfs

```shell
docker run -e MAPSERVER_CONFIG_FILE=/srv/data/example.conf -e MS_MAPFILE=/srv/data/example.map -e SERVICE_TYPE=WFS  --rm -d \
            -p 80:80 --name mapserver-example -v `pwd`/example:/srv/data pdok/mapserver 
```

### docker stop

```shell
docker stop mapserver-example
```

## Introduction

This project aims to fulfill two needs:

1. create [OGC services](http://www.opengeospatial.org/standards) that are
   deployable on a scalable infrastructure.
2. create a useable [Docker](https://www.docker.com) base image.

Fulfilling the first need the main purpose is to create an Docker base image
that can be run on a platform like [Kubernetes](https://kubernetes.io/).

Regarding the second need, finding a usable
[Mapserver](https://github.com/mapserver/mapserver) Docker image is a challenge.
Most images expose the &map=... QUERY_STRING in the GetCapabilities, don't run
in FastCGI and are based on Apache.

## What will it do

It will create an Mapserver application that runs through
[lighttpd](https://www.lighttpd.net/). With lua scripting the map=...
QUERY_STRING is filter from incoming request. In other words the used Mapfile
can only be set with an ENV.

The included EPSG file containing the projection parameters only contains a
small set of available EPSG code, namely the once used by our organization. If
one wants to use additional EPSG projections one can overwrite this file.

## Docker image

The Docker image contains 2 stages:

1. builder
2. service

### builder

The builder stage compiles Mapserver. The Dockerfile contains all the available
Mapserver build option explicitly, so it is clear which options are enabled and
disabled.

### service

The service stage copies the Mapserver application, build in the first stage to
the service stage, and configures lighttpd

## Usage

### Build

```shell
docker build -t pdok/mapserver .
```

For a specific Dutch version which includes a specific (and smaller) epsg file
and necessary grid corrections files.

```shell
docker build -t pdok/mapserver:nl -f Dockerfile.NL .
```

### Run

This image can be run straight from the command-line. A  volume needs to be
mounted on the container directory `/srv/data`. The mounted volume needs to
contain a mapserver `*.map` file that matches the `MS_MAPFILE` env var.

```shell
docker run \
   --rm -d \
   -e MS_MAPFILE=/srv/data/example.map \
   -p 80:80 \
   --name mapserver-example \
   -v `pwd`/example:/srv/data \
   pdok/mapserver
```

Running the example above will create a service on the url
<http://localhost/mapserver?REQUEST=GetCapabilities&SERVICE=WMS> that will
accept something like a ([GetMap
request](http://localhost/mapserver?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&BBOX=50,2.423859315589366403,54,9&CRS=EPSG:4326&WIDTH=1648&HEIGHT=1002&LAYERS=example&STYLES=&FORMAT=image/png&DPI=96&MAP_RESOLUTION=96&FORMAT_OPTIONS=dpi:96&TRANSPARENT=TRUE)).

The environment variables that can be set are the following:

- `DEBUG`
- `MIN_PROCS`
- `MAX_PROCS`
- `MAX_LOAD_PER_PROC`
- `IDLE_TIMEOUT`
- `MS_MAPFILE`
- `PROJ_LIB`

The environment variables, with the exception of `MS_MAPFILE` have a default
value set in the [`Dockerfile`](./Dockerfile).

The [GDAL](https://gdal.org/) `PROJ_LIB` env var is default set with the value
`/usr/share/proj`. For performance reasons one would like to set a custom
`PROJ_LIB` containing a minimum of available EPSG codes. This can be done with
the mentioned `PROJ_LIB` env var.

```shell
docker run \
   --rm -d \
   -p 80:80 \
   --name mapserver-run-example \
   -v `pwd`/example:/srv/data \
   -e DEBUG=0 \
   -e MIN_PROCS=1 \
   -e MAX_PROCS=3 \
   -e MAX_LOAD_PER_PROC=4 \
   -e IDLE_TIMEOUT=20 \
   -e MS_MAPFILE=/srv/data/example.map \
   pdok/mapserver
```

## Projections

Altering the proj file is done for different reasons, adding custom projections
or removing 'unused' ones for better performance. This can be done in a couple
of ways through this setup.

### base image

The best example for this is the [Dockerfile.NL](/Dockerfile.NL) in this
repository. This Dockerfile uses the main Dockerfile as a base image copies
specific geodetic grid files and overwrites the default espg with a tuned one
for the Netherlands.

A good resource for these geodetic files is the [PROJ.org Datumgrid
CDN](https://cdn.proj.org/).

### volume

Another option is to create a proj file (like in the [`nl`](/nl) folder) and
mount this to the container and set the `PROJ_LIB` env var to that location by
adding the following parameters to the docker command:

```sh
-e PROJ_LIB=/my-custom-proj-dir \
-v `pwd`/path/to/proj/dir:/my-custom-proj-dir \
```

## Example

When starting the container it will create a WMS & WFS service on the
accespoint: `http://localhost/mapserver`.

### Example requests

#### WMS

Example requests when the container is run as WMS service

- [`http://localhost/mapserver?SERVICE=WMS&REQUEST=GetCapabilities`](http://localhost/mapserver?SERVICE=WMS&REQUEST=GetCapabilities)
- [`http://localhost/mapserver?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&BBOX=50,2,54,9&CRS=EPSG:4326&WIDTH=905&HEIGHT=517&LAYERS=example&STYLES=&FORMAT=image/png&DPI=96&MAP_RESOLUTION=96&FORMAT_OPTIONS=dpi:96&TRANSPARENT=TRUE`](http://localhost/mapserver?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&BBOX=50,2,54,9&CRS=EPSG:4326&WIDTH=905&HEIGHT=517&LAYERS=example&STYLES=&FORMAT=image/png&DPI=96&MAP_RESOLUTION=96&FORMAT_OPTIONS=dpi:96&TRANSPARENT=TRUE)
- [`http://localhost/mapserver?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo&BBOX=48.9306039592783506,0.48758765231731171,55.46504193821721884,12.33319204541738756&CRS=EPSG:4326&WIDTH=1530&HEIGHT=844&LAYERS=example&STYLES=&FORMAT=image/png&QUERY_LAYERS=example&INFO_FORMAT=text/html&I=389&J=537&FEATURE_COUNT=10`](http://localhost/mapserver?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo&BBOX=48.9306039592783506,0.48758765231731171,55.46504193821721884,12.33319204541738756&CRS=EPSG:4326&WIDTH=1530&HEIGHT=844&LAYERS=example&STYLES=&FORMAT=image/png&QUERY_LAYERS=example&INFO_FORMAT=text/html&I=389&J=537&FEATURE_COUNT=10)

#### WFS

Example requests when the container is run as WFS service

- [`http://localhost/mapserver?SERVICE=WFS&REQUEST=GetCapabilities`](http://localhost/mapserver?SERVICE=WFS&REQUEST=GetCapabilities)
- [`http://localhost/mapserver?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature&TYPENAMES=example:example&COUNT=1`](http://localhost/mapserver?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature&TYPENAMES=example:example&COUNT=1)

## Misc

### Why Lighttpd

In our previous configurations we would run [NGINX](https://www.nginx.com/),
while this is a good web service and has a lot of configuration options, it runs
with multiple processes. There for we needed supervisord for managing this,
whereas [lighttpd](https://www.lighttpd.net/) runs as a single process. Also all
the routing configuration options aren't needed, because that is handled by the
infrastructure/platform, like [Kubernetes](https://kubernetes.io/). If one would
like to configure some simple routing is still can be done in the lighttpd.conf.

### Used examples

- <https://github.com/srounet/docker-mapserver>
- <https://github.com/Amsterdam/mapserver>
