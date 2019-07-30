# Mapserver docker

![GitHub release](https://img.shields.io/github/release/PDOK/mapserver-docker.svg)
![Docker Pulls](https://img.shields.io/docker/pulls/pdok/mapserver.svg)

## TL;DR

```docker
docker build -t pdok/mapserver .
docker run -e MS_MAPFILE=/srv/data/example.map -d -p 80:80 --name mapserver-example -v `pwd`:/srv/data pdok/mapserver

docker stop mapserver-example
docker rm mapserver-example
```

## Introduction

This project aims to fulfill two needs:

1. create a [OGC services](http://www.opengeospatial.org/standards) that are deployable on a scalable infrastructure.
2. create a useable [Docker](https://www.docker.com) base image.

Fulfilling the first need the main purpose is to create an Docker base image that can be run on a platform like [Kubernetes](https://kubernetes.io/).

Regarding the second need, finding a usable Mapserver Docker image is a challenge. Most images expose the &map=... QUERY_STRING in the getcapabilities, don't run in fastcgi and are based on Apache.

## What will it do

It will create an Mapserver application run with Lighttpd in which the map=... QUERY_STRING 'issue' is 'fixed'. This means that the MAP query parameter is removed from the QUERY_STRING.

The included EPSG file containing the projection parameters only contains a small set of available EPSG code, namely the once used by our organisation. If one wants to use additional EPSG projections one can overwrite this file.

## Docker image

The Docker image contains 2 stages:

1. builder
2. service

### builder

The builder stage compiles Mapserver. The Dockerfile contains all the available Mapserver build option explicitly, so it is clear which options are enabled and disabled.

### service

The service stage copies the Mapserver application, build in the first stage the service stage, and configures Lighttpd & the epsg file.

## Usage

### Build

```docker
docker build -t pdok/mapserver .
```

### Run

This image can be run straight from the commandline. A volumn needs to be mounted on the container directory /srv/data. The mounted volumn needs to contain at least one mapserver *.map file. The name of the mapfile will determine the URL path for the service.

```docker
docker run -e MS_MAPFILE=/srv/data/example.map -d -p 80:80 --name mapserver-example -v `pwd`:/srv/data pdok/mapserver
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

The gdal PROJ_LIB env is default set with the value /usr/share/proj. For performance reasons one would like to set a custom PROJ_LIB containing a minimum of available EPSG codes. This can be done with the mentioned PROJ_LIB env.

```docker
docker run -e DEBUG=0 -e MIN_PROCS=1 -e MAX_PROCS=3 -e MAX_LOAD_PER_PROC=4 -e IDLE_TIMEOUT=20 -e MS_MAPFILE=/srv/data/example.map -d -p 80:80 --name mapserver-run-example -v /path/on/host:/srv/data pdok/mapserver
```

## Misc

### Why Lighttpd

In our previous configurations we would run NGINX, while this is a good webservice and has a lot of configuration options, it runs with multiple processes. There for we needed supervisord for managing this, whereas Lighthttpd runs as a single proces. Also all the routing configuration options aren't needed, because that is handled by the infrastructure/platform, like Kubernetes. If one would like to configure some simple routing is still can be done in the lighttpd.conf.

### Used examples

* <https://github.com/srounet/docker-mapserver>
* <https://github.com/Amsterdam/mapserver>
