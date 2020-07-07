# ereadingtool
Build [![CircleCI](https://circleci.com/gh/ereadingtool/ereadingtool.svg?style=svg)](https://circleci.com/gh/ereadingtool/ereadingtool)

## Web

### Setup

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
local development.

```
parcel src/index.html
```

## Build

Both `parcel` build commands compile to the `dist` directory.

To compile a development build without optimization

```
parcel build src/index.html --no-minify
```

To compile an optimized production build

```
parcel build src/index.html
```

All debug statements must be removed for the optimized build.