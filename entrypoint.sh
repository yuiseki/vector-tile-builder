#!/bin/sh

cd /app
make
tileserver-gl-light tmp/region.mbtiles
