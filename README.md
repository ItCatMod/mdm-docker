# Mauro Data Mapper Docker

The entire system can be run up using this repository
The following components are part of this system:

* Mauro Data Mapper [maurodatamapper] - Mauro Data Mapper
* Postgres 12 [postgres] - Postgres Database

## Table Of Contents

- [Mauro Data Mapper Docker](#mauro-data-mapper-docker)
  - [Table Of Contents](#table-of-contents)
  - [Dependencies](#dependencies)
  - [Building](#building)
  - [Run Environment](#run-environment)
  - [Migrating from Metadata Catalogue](#migrating-from-metadata-catalogue)
  - [Docker](#docker)
    - [The Docker Machine](#the-docker-machine)
    - [Configuring shell to use the default Docker Machine](#configuring-shell-to-use-the-default-docker-machine)
    - [Cleaning up docker](#cleaning-up-docker)
  - [Running](#running)
    - [Optional `docker` only (no `docker-compose`)](#optional-docker-only-no-docker-compose)
  - [Developing](#developing)
    - [Running in development environment](#running-in-development-environment)
    - [Try to keep images as small as possible](#try-to-keep-images-as-small-as-possible)
    - [Make use of the wait_scripts.](#make-use-of-the-waitscripts)
    - [Use `ENTRYPOINT` & `CMD`](#use-entrypoint-cmd)
    - [`COPY` over `ADD`](#copy-over-add)
    - [`docker-compose`](#docker-compose)

## Dependencies

If using `Windows` or `OSX` you will need to install Docker.
Currently the minimum level of docker is

* Engine: 19.03.8
* Compose: 1.25.5

---

## Building

**Please note this whole build system is still a work in progress and may not start up as expected,
also some properties may not be set as expected**

Currently you will need to 

1. Build mdm-server using `grails war`
1. Extract the war file to a folder
1. Copy the contents of the extracted folder to `mauro-data-mapper/lib/build`, nominally
    1. META-INF
    1. org
    1. WEB-INF
1. Build the mdm-ui using `ng build --prod`
1. Copy the contents of the `dist` folder to `mauro-data-mapper/lib/build`
1. Run `docker-compose build`

The above will build the Mauro Data Mapper into the `ROOT` directory of the Tomcat webapps folder.

---

## Run Environment

### Environment Notes

**Database** The system is designed to use the postgres service provided in the docker-compose file, therefore there should be no need to alter any of
these settings. Only make alterations if running postgres as a separate service outside of docker-compose.

**Web Api** The provided values will be used to define the CORS allowed origins. The port will be used to define http or https(443), if its not 80
 or 443 then it will be added to the url generated. The host must be the host used in the web url when accessing the catalogue in a web browser.
 
 **Email** The standard email properties will allow emails to be sent to a specific SMTP server. The `emailservice` properties override this and 
 send the email to the specified email service which will then forward it onto our email SMTP server.

---

## Migrating from Metadata Catalogue

Please see the [mc-to-mdm-migration](https://github.com/MauroDataMapper/mc-to-mdm-migration) repository for details.

You will need to have started up this docker service once to ensure the database and volume exists for the Mauro Data Mapper.

---

## Docker

### The Docker Machine
The default `docker-machine` in a Windows or Mac OS X environment is 1 CPU and 1GB RAM, this is not enough to run the Mauro Data Mapper system.
On Linux the docker machine is the host machine so there is no need to build or remove anything.

#### Native Docker

If using the Native Docker then edit the preferences of the Docker application and increase the RAM to at least 4GB,
you will probably need to restart Docker after doing this.

#### Docker Toolbox

If using the Docker Toolbox then as such you will need to perform the following in a 'docker' terminal.

```bash
# Stop the default docker machine
$ docker-machine stop default

# Remove the default machine
$ docker-machine rm default

# Replace with a more powerful machine (4096 is the minimum recommended RAM, if you can give it more then do so)
$ docker-machine create --driver virtualbox --virtualbox-cpu-count "-1" --virtualbox-memory "4096" default
```

##### Configuring shell to use the default Docker Machine

When controlling using Docker Machine via your terminal shell it is useful to set the `default` docker machine.
Type the following at the command line, or add it to the appropriate bash profile file:

```bash
eval "$(docker-machine env default)"
```

If not you may see the following error: `Cannot connect to the Docker daemon. Is the docker daemon running on this host?`


### Cleaning up docker

Continually building docker images will leave a lot of loose snapshot images floating around, occasionally make use of:

* Clean up stopped containers - `docker rm $(docker ps -a -q)`
* Clean up untagged images - `docker rmi $(docker images | grep "^<none>" | awk "{print $3}")`
* Clean up dangling volumes - `docker volume rm $(docker volume ls -qf dangling=true)`

You can make life easier by adding the following to the appropriate bash profile file:

```bash
alias docker-rmi='docker rmi $(docker images -q --filter "dangling=true")'
alias docker-rm='docker rm $(docker ps -a -q)'
alias docker-rmv='docker volume rm $(docker volume ls -qf dangling=true)'
```

Remove all stopped containers first then remove all tagged images.

A useful tool is [Dockviz](https://github.com/justone/dockviz),
ever since docker did away with `docker images --tree` you can't see all the layers of images and therefore how much floating mess you have.

Add the following to to the appropriate bash profile file:

 ```bash
 alias dockviz="docker run --privileged -it --rm -v /var/run/docker.sock:/var/run/docker.sock nate/dockviz"
 ```

Then in a new terminal you can run `dockviz images -t` to see the tree,
the program also does dot notation files for a graphical view as well.

### Multiple compose files

When you supply multiple files, docker-compose combines them into a single configuration.
Compose builds the configuration in the order you supply the files.
Subsequent files override and add to their successors.

```bash
# Apply the .dev yml file, create and start the containers in the background
$ docker-compose -f docker-compose.yml -f docker-compose.dev.yml -d <COMMAND>

# Apply the .prod yml file, create and start the containers in the background
$ docker-compose -f docker-compose.yml -f docker-compose.prod.yml -d <COMMAND>
```

We recommend adding the following lines to the appropriate bash profile file:

```bash
alias docker-compose-dev="docker-compose -f docker-compose.yml -f docker-compose.dev.yml"
alias docker-compose-prod="docker-compose -f docker-compose.yml -f docker-compose.dev.yml"
```
This will allow you to start compose in dev mode without all the extra file definitions

---

## Running

Before running please read the [parameters](parameters) section first.

With `docker` and `docker-compose` installed, run the following:

```bash
# Build all the images
$ docker-compose-dev build

# Start all the components up
$ docker-compose up -d

# To only start 1 service
# This will also start up any of the services the named service depends on (defined by `links` or `depends_on`)
$ docker-compose up [SERVICE]

# To push all the output to the background add `-d`
$ docker-compose up -d [SERVICE]

# Stop background running and remove the containers
$ docker-compose down

# To update an already running service
$ docker-compose-dev build [SERVICE]
$ docker-compose up -d --no-deps [SERVICE]

# To run in production mode
$ docker-compose-prod up -d [SERVICE]
```

If you run everything in the background use `Kitematic` to see the individual container logs.
You can do this if running in the foreground and its easier as it splits each of the containers up.

If only starting a service when you stop the service docker will *not* stop the dependencies that were started to allow the named service to start.

The default compose file will pull the correct version images from Bintray, or a locally defined docker repository.

---

## Developing

### Running in development environment

There is an extra override docker-compose file for development, this currently opens up the ports in

* postgres

### Building images

The `.dev` compose file builds all of the images,
the standard compose file and `.prod` versions **do not** build new images.


**Try to keep images as small as possible**

### Make use of the wait_scripts.

While `-links` and `depends_on` make sure the services a service requires are brought up first Docker only waits till they are running NOT till they
are actually ready.
The wait scripts allow testing to make sure the service is actually available.

**Note**: If requiring postgres and using any of the Alpine Linux base images then the Dockerfile  will need to add the following:

`RUN apk add postgresql-client`

### Use `ENTRYPOINT` & `CMD`

* If not requiring any dependencies then just set `CMD ["arg1", ...]` and the args will be passed to the `ENTRYPOINT`
* If requiring dependencies then set the `ENTRYPOINT` to the wait script and the `CMD` to `CMD ["process", "arg1", ...]`

**Note**: We should be able to override the `ENTRYPOINT` in the docker-compose but for some reason its not then passing the CMD args through.

### `COPY` over `ADD`

Docker recommends using COPY instead of ADD unless the source is a URL or a tar file which ADD can retrieve and/or unzip.,=

### `docker-compose`

Careful thought about what is required and what ports need to be passed through.
If the port only needs to be available to other docker services then use `expose`.
If the port needs to be open outside (e.g. the LabKey port 8080) then use `ports`.

If the `ports` option is used this opens the port from the service to the outside world,
it does not affect `exposed` ports between services, so if a service (e.g. postgres with port 5432) exposes a port
then any service which used `link` to `postgres` will be able to find the database at `postgresql://postgres:5432`

## Releases

All work should be done on the `develop` branch.