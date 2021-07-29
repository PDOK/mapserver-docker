# Mapserver docker

[![GitHub license](https://img.shields.io/github/license/PDOK/mapserver-docker)](https://github.com/PDOK/mapserver-docker/blob/master/LICENSE)
[![GitHub release](https://img.shields.io/github/release/PDOK/mapserver-docker.svg)](https://github.com/PDOK/mapserver-docker/releases)
[![Docker Pulls](https://img.shields.io/docker/pulls/pdok/mapserver.svg)](https://hub.docker.com/r/pdok/mapserver)

## TL;DR

```docker
docker build -t pdok/mapserver .
docker run -e MS_MAPFILE=/srv/data/example.map --rm -d -p 80:80 --name mapserver-example -v `pwd`/example:/srv/data pdok/mapserver

docker stop mapserver-example
```

## Introduction

This project aims to fulfill two needs:

1. create [OGC services](http://www.opengeospatial.org/standards) that are deployable on a scalable infrastructure.
2. create a useable [Docker](https://www.docker.com) base image.

Fulfilling the first need the main purpose is to create an Docker base image that can be run on a platform like [Kubernetes](https://kubernetes.io/).

Regarding the second need, finding a usable [Mapserver](https://github.com/mapserver/mapserver) Docker image is a challenge. Most images expose the &map=... QUERY_STRING in the GetCapabilities, don't run in FastCGI and are based on Apache.

## What will it do

It will create an Mapserver application run with Lighttpd in which the map=... QUERY_STRING 'issue' is 'fixed'. This means that the MAP query parameter is removed from the QUERY_STRING.

The included EPSG file containing the projection parameters only contains a small set of available EPSG code, namely the once used by our organization. If one wants to use additional EPSG projections one can overwrite this file.

## Docker image

The Docker image contains 2 stages:

1. builder
2. service

### builder

The builder stage compiles Mapserver. The Dockerfile contains all the available Mapserver build option explicitly, so it is clear which options are enabled and disabled.

### service

The service stage copies the Mapserver application, build in the first stage to the service stage, and configures Lighttpd

## Usage

### Build

```docker
docker build -t pdok/mapserver .
```

For a specific Dutch version which includes a specific (and smaller) epsg file and necessary grid corrections files.

```docker
docker build -t pdok/mapserver:nl -f Dockerfile.NL .
```

### Run

This image can be run straight from the CLI. A  volume needs to be mounted on the container directory /srv/data. The mounted volume needs to contain a mapserver *.map file that matches the MS_MAPFILE env.

```docker
docker run -e MS_MAPFILE=/srv/data/example.map -d -p 80:80 --name mapserver-example -v `pwd`/example:/srv/data pdok/mapserver
```

Running the example above will create a service on the url <http://localhost/?request=getcapabilities&service=wms>

The ENV variables that can be set are the following

```env
DEBUG
MIN_PROCS
MAX_PROCS
MAX_LOAD_PER_PROC
IDLE_TIMEOUT
MS_MAPFILE

PROJ_LIB
```

The ENV variables, with the exception of MS_MAPFILE have a default value set in the Dockerfile.

The [GDAL](https://gdal.org/) PROJ_LIB env is default set with the value /usr/share/proj. For performance reasons one would like to set a custom PROJ_LIB containing a minimum of available EPSG codes. This can be done with the mentioned PROJ_LIB env.

```docker
docker run -e DEBUG=0 -e MIN_PROCS=1 -e MAX_PROCS=3 -e MAX_LOAD_PER_PROC=4 -e IDLE_TIMEOUT=20 -e MS_MAPFILE=/srv/data/example.map --rm -d -p 80:80 --name mapserver-run-example -v `pwd`/example:/srv/data pdok/mapserver
```

## Example

When starting the container it will create a WMS & WFS service on the end-point

```html
http://localhost?
```

### Example request

```html
http://localhost/?request=getfeature&service=wfs&VERSION=2.0.0&typename=example:example&count=1
```

```html
http://localhost/?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&BBOX=50,2,54,9&CRS=EPSG:4326&WIDTH=905&HEIGHT=517&LAYERS=example&STYLES=&FORMAT=image/png&DPI=96&MAP_RESOLUTION=96&FORMAT_OPTIONS=dpi:96&TRANSPARENT=TRUE
```

```html
http://localhost/?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo&BBOX=48.9306039592783506,0.48758765231731171,55.46504193821721884,12.33319204541738756&CRS=EPSG:4326&WIDTH=1530&HEIGHT=844&LAYERS=example&STYLES=&FORMAT=image/png&QUERY_LAYERS=example&INFO_FORMAT=text/html&I=389&J=537&FEATURE_COUNT=10
```

## Misc

### Why Lighttpd

In our previous configurations we would run NGINX, while this is a good web service and has a lot of configuration options, it runs with multiple processes. There for we needed supervisord for managing this, whereas Lighttpd runs as a single process. Also all the routing configuration options aren't needed, because that is handled by the infrastructure/platform, like [Kubernetes](https://kubernetes.io/). If one would like to configure some simple routing is still can be done in the lighttpd.conf.

### Used examples

* <https://github.com/srounet/docker-mapserver>
* <https://github.com/Amsterdam/mapserver>
