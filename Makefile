export

all: tmp/region.pbf tmp/region.geojsonseq tmp/tiles.mbtiles docs/zxy/metadata.json docs/style.json

clean:
	rm -f tmp/region.pbf tmp/region.geojsonseq tmp/tiles.mbtiles docs/zxy/metadata.json docs/style.json

# Download OpenStreetMap data as Protocolbuffer Binary Format file
tmp/region.pbf:
	curl -C - https://download.geofabrik.de/${REGION}-latest.osm.pbf --output 'tmp/region.pbf'

# Export region.pbf as GeoJSONSeq Format file
tmp/region.geojsonseq:
	osmium export \
		--config osmium-export-config.json \
		--index-type=sparse_file_array \
		--output-format=geojsonseq \
		--output=tmp/region.geojsonseq \
		tmp/region.pbf

# Build MBTiles Format file from GeoJSONSeq Format file
tmp/tiles.mbtiles:
	tippecanoe \
		--no-feature-limit \
		--no-tile-size-limit \
		--force \
		--simplification=2 \
		--maximum-zoom=15 \
		--base-zoom=15 \
		--hilbert \
		--output=tmp/tiles.mbtiles \
		tmp/region.geojsonseq

# Split MBTiles Format file into zxy Protocolbuffer Binary Format files
docs/zxy/metadata.json:
	tile-join \
		--force \
		--no-tile-compression \
		--no-tile-size-limit \
		--output-to-directory=docs/zxy \
		tmp/tiles.mbtiles

docs/style.json:
	charites init -m docs/zxy/metadata.json docs/style.json

.PHONY: serve
serve:
	charites serve style.yml
