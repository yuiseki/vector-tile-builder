include .env

all: tmp/region.pbf tmp/region.geojson tmp/region.mbtiles docs/zxy/metadata.json

.PHONY: clean
clean:
	rm -rf tmp/region.pbf tmp/region.geojson tmp/region.mbtiles tmp/layers/*.geojson docs/zxy/*

.PHONY: start
start:
	npx http-server docs --cors true -p 9090

# Download OpenStreetMap data as Protocolbuffer Binary Format file
tmp/region.pbf:
	curl -C - https://download.geofabrik.de/${REGION}-latest.osm.pbf --output 'tmp/region.pbf'

# Export region.pbf as GeoJSONSeq Format file
tmp/region.geojson:
	osmium export \
		--config osmium-export-config.json \
		--output-format=geojsonseq \
		--output=tmp/region.geojson \
		tmp/region.pbf

# split region.geojson to layers
layer_files = \
	tmp/layers/boundary.geojson \
	tmp/layers/place.geojson \
	tmp/layers/landcover.geojson \
	tmp/layers/landuse.geojson \
	tmp/layers/water.geojson \
	tmp/layers/waterway.geojson \
	tmp/layers/aeroway.geojson \
	tmp/layers/transportation.geojson \
	tmp/layers/park.geojson \
	tmp/layers/building.geojson

$(layer_files):
	cat tmp/region.geojson | grep -E '"boundary":' > tmp/layers/boundary.geojson
	cat tmp/region.geojson | grep -E '"place":' > tmp/layers/place.geojson
	cat tmp/region.geojson | grep -E '"landcover":' > tmp/layers/landcover.geojson
	cat tmp/region.geojson | grep -E '"landuse":' > tmp/layers/landuse.geojson
	cat tmp/region.geojson | grep -E '"natural":"water"' > tmp/layers/water.geojson
	cat tmp/region.geojson | grep -E '"waterway":' > tmp/layers/waterway.geojson
	cat tmp/region.geojson | grep -E '"aeroway":' > tmp/layers/aeroway.geojson
	cat tmp/region.geojson | grep -E 'highway|railway|tunnel|bridge|road' > tmp/layers/transportation.geojson
	cat tmp/region.geojson | grep -E '"leisure":"park"' > tmp/layers/park.geojson
	cat tmp/region.geojson | grep -E '"building":' > tmp/layers/building.geojson

# Build MBTiles Format file from tmp/layers/*.geojson
tmp/region.mbtiles: $(layer_files)
	tippecanoe \
		-P \
		--no-tile-compression \
		--simplification=5 \
		--drop-densest-as-needed \
		--drop-fraction-as-needed \
		--drop-smallest-as-needed \
		--maximum-zoom=g \
		--generate-ids \
		--hilbert \
		--output=tmp/region.mbtiles \
		tmp/layers/*.geojson

# Split MBTiles Format file into zxy Protocolbuffer Binary Format files
docs/zxy/metadata.json:
	tile-join \
		--no-tile-compression \
		--no-tile-size-limit \
		--no-tile-stats \
		--output-to-directory=docs/zxy \
		tmp/region.mbtiles
