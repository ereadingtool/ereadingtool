## Build

Build [![CircleCI](https://circleci.com/gh/ereadingtool/ereadingtool.svg?style=svg)](https://circleci.com/gh/ereadingtool/ereadingtool)

# ereadingtool
The ereadingtool allows students and instructors to consume or provide a language's texts and interactively view its translations. Since languages rarely have a one-to-one mapping, texts created on the app can have their translation modified or changed. Students who consume the text material are presented questions created by an instructor for that particular text. Scores and progress is tracked and can be converted to a PDF for alternative viewing.

## Overview
Ereadingtool is a SPA delivered by an NGINX webserver. The SPA communicates with a Django API server using a REST-ful paradigm. The Django web framework utilizes websocket connections for smooth interaction between the client and the server. It is supported by a Redis in-memory database to quickly serve the texts to the client over this websocket connection. Note that this is a microservice architecture deployed to a single server. The internet facing container is an NGINX reverse-proxy which routes traffic to either the API server or an NGINX webserver which servers the Elm app. The API server connects to a Redis container on the default port. Both the API server and the NGINX webserver are furnished Let's Encrypt certs by the lets-encrypt-nginx-proxy-companion. These certs, and the routing information for the reverse-proxy, is designated by the docker-gen container. For security purposes it does not have the docker socket facing the internet.

## Usage
To run the app locally, follow the instructions in the **Web** section and the **Server** section. Either order is fine, just be sure to run the API server on a different port than the Elm app is served from.

To host the app, deploy it to a server with exposed ports `80` and `443`. Bind a static IP address to the instance and `ssh` onto it. From here, update the server's OS. You'll also need to install Docker and Docker Compose. Instructions to do that can be found in the **Resources** section below. Be sure to add the user to the Docker group.

Next you'll want to pull in the necessary files to the instance. This can be done in a variety of ways, if you using a cloud provider like AWS or GCP I'd recommend their CLI tools to `scp` the files over. While some of them are included in the code base, you certainly do not need the code itself. Listed below are the files necessary to spin up the system.

```
docker-compose.yml - Builds the system
Dockerfile.django - Constructs the API server
Dockerfile.node  - Constructs the frontend
cors.conf - Uses Docker volumes to mount in shared location. Adds CORS headers to responses
db.sqlite3 - The database full of instructors and users
nginx.tmpl - Template file used by docker-gen to create reverse-proxy routing mechanism (nginx-proxy) 
secrets.env - Secret environment variables 
steps2ar.org - NGINX config file copied onto the node_frontend container. Change name accordingly.
```

Once these are on the instance simply run: 

```
docker-compose up
```

## Local development
You'll want to use two shells here, one running a npm devlopment server out of the `web/` directory. 
The other is to run the Django dev server at the project root. There are a couple of things to set in 
the file `ereadingtools/settings.py` in order to make it work and provide verbose debugging output. 
One setting is `DEBUG=True`. It makes plenty of sense that you'll want this if you're running in a local
environment. Placing this statement at the top level of the settings file will do the trick.

Another change to the settings file is regarding the host setting for redis in the `CHANNEL_LAYERS`. 
Regardless of how you run Redis, whether that's a container on your local machine or running natively, 
you'll want to set it to `localhost`. Unless of course you do some magic with `/etc/hosts` or are planning
to run the whole thing in a docker network anyways. 


#### Email
To have emails sent by SendGrid, you'll need to have `SENDGRID_SANDBOX_MODE_IN_DEBUG=False` in `settings.py`. 
Refer to issue #239 for more details.

You'll need to set a local environment variable so that the backend is aware of the frontend. Specifically, `FRONTEND_HOST=localhost:1234`. If you're live firing the forgot email functionality from the frontend, you'll be sending the client to the api server if this env var isn't set.

#### Tests
Easily the best testing environment for this is VSCode. To enable tests, be sure to look at the launch.json file 
and confirm there is configuration with an `args` value `test`. Then, you'll want to go to the test section of 
VSCode and choose to `RUN` the name of your test configuration. Unreconciled issues finding database tables may 
exist. Try storing then nuking your migrations from space.

## Web

### Setup

Change into the `web` directory.

```
cd web/
```

Install `elm` at version `0.19.1`. 

```
npm install -g elm
```

Install `parcel`.

```
npm install -g parcel-bundler
```

Install the npm packages from the `web` directory.

```
npm install
```

### Develop 

`parcel` provides a local webserver and hot reloading which are useful during
local development. We call `elm-spa` and `parcel` with `npm`.

```
npm start
```

### Build

Both build commands compile to the `dist` directory.

To compile a development build without optimization

```
npm run build:staging
```

To compile an optimized production build

```
npm run build
```

All debug statements must be removed for the optimized build.

### Environment variables

Environment variables are stored `.env.local` for local development, `.env.devel` for the development server build, and `.env.production` for the production build.

There may be occassional caching problems when using these environments. Deleting `.cache/` and `dist/` will usually help.

## Server

### Virtual Environment

You'll need to create a virtual environment to keep the dependencies for this project contained. With `virtualenv` installed, use the following commands.

```
virtulenv -p python3 venv
source venv/bin/activate
pip install -r requirements.txt
```

### Develop
Be sure to have your virtualized environment activated. From the project's root directory run:

```
python manage.py runserver
```

## Resources

#### Docker & Docker Compose
Blogs and links to help install on Ubuntu 18.04
!(Docker Compose)[https://linuxize.com/post/how-to-install-and-use-docker-compose-on-ubuntu-18-04/]
!(Docker)[https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04]
