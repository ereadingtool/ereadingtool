# Elm Frontend Readme

The Lunar Rocks frontend is an Elm 0.19 application.

==================================================

## Setup

Install `elm` and `elm-test` at version `0.19.0`. 

```
npm install -g elm@0.19.0
npm install -g elm-test@0.19.0
```

Install `parcel`.

```
npm install -g elm parcel-bundler
```


Install the npm packages from the `client` directory.

```
npm install
```

## Develop 

`parcel` provides a local webserver and hot reloading which are useful during
local development.

```
parcel src/index.html
```

## Build

Both `parcel` build commands emit compiled artifacts to the `dist` directory for
consumption by the Lunar Rocks webserver.

Compile a development build without optimization.

```
parcel build src/index.html --no-minify
```

Compile an optimized production build.

```
parcel build src/index.html
```

All debug statements must be removed for the optimized build.

## Attribution

Many of the modules in this application are based on the [elm-spa-example](https://github.com/rtfeldman/elm-spa-example/blob/master/src/Page/Register.elm), and the Main module is partly based on the [elm-tutorial-app](https://github.com/sporto/elm-tutorial-app/blob/master/src/Main.elm).


