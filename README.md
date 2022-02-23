# vector-tile-builder

## What is this

This repos allows you to build, customize and deploy your own vector tile maps from the data of OpenStreetMap.

## How it works

This repos depends on the following softwares:

- tilemaker
  - https://github.com/systemed/tilemaker
  - Most important software
  - Make MBTiles file that following OpenMapTiles scheme from the data of OpenStreetMap
- tippecanoe
  - https://github.com/mapbox/tippecanoe
  - Also important software
  - Split MBTiles file into zxy style directory and PBF files
- Node.js
  - http-server
    - https://github.com/http-party/http-server
    - Simple, configure less http server
  - mbtiles2tilejson
    - https://github.com/yuiseki/mbtiles2tilejson
    - Make TileJSON file from MBTiles file
  - @unvt/charites
    - https://github.com/unvt/charites
    - Make JSON file that following Mapbox Style Specification from split yml files.

## Structure

- /conf
  - Configure files for Raspberry Pi
- /docs
  - Final product of this repos
- /layers
  - Style definition files to customize appearance of maps
- /tmp
  - Temporary directory to leave the intermediate products behind

## Build and Deploy vector tile maps on...

### GitHub Actions and GitHub Pages

Read [README_GitHub_Pages.md](./README_GitHub_Pages.md)

### Raspberry Pi

Read [README_Raspberry_Pi.md](./README_Raspberry_Pi.md)

## Development

### Requirements

- git
- curl
- GNU sed
- GNU make
- Docker

I believe GNU, So I don't care about other `sed` or `make`.  
Why don't you believe GNU?
