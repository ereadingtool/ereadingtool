# ereadingtool
The ereadingtool allows students and instructors to consume or provide a language's texts and interactively view its translations. Since languages rarely have a one-to-one mapping, texts created on the app can have their translation modified or changed. Students who consume the text material are presented questions created by an instructor for that particular text. Scores and progress is tracked and can be converted to a PDF for alternative viewing.

## Overview
Ereadingtool is a SPA delivered by an Nginx webserver. The SPA communicates with a Django API server using a REST-ful paradigm. The Django web framework utilizes websocket connections for smooth interaction between the client and the server. It is supported by a Redis in-memory database to quickly serve the texts to the client over this websocket connection. 

## Usage
To run the app locally, follow the instructions in the **Web** section and the **Server** section. Either order is fine, just be sure to run the API server on a different port than the Elm pages are served from.

To host the app, deploy it to a server with exposed ports `80` and `443`. Bind a static IP address, to the instance and `ssh` onto it. From here, update the server's OS. You'll also need to install t

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

#### stuff about Django goes here


## Build

Build [![CircleCI](https://circleci.com/gh/ereadingtool/ereadingtool.svg?style=svg)](https://circleci.com/gh/ereadingtool/ereadingtool)