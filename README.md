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
local development. We call `elm-spa` and `parcel` with `npm`.

```
npm start
```

## Build

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