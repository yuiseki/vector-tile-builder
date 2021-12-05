export

all: tmp/region.pbf tmp/region.geojsonseq docs/tiles.mbtiles docs/zxy/metadata.json

clean:
	rm -f tmp/region.pbf tmp/region.geojsonseq docs/tiles.mbtiles docs/zxy/metadata.json

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
docs/tiles.mbtiles:
	tippecanoe \
		--no-feature-limit \
		--no-tile-size-limit \
		--force \
		--simplification=2 \
		--maximum-zoom=15 \
		--base-zoom=15 \
		--hilbert \
		--output=docs/tiles.mbtiles \
		tmp/region.geojsonseq

# Split MBTiles Format file into zxy Protocolbuffer Binary Format files
docs/zxy/metadata.json:
	tile-join \
		--force \
		--no-tile-compression \
		--no-tile-size-limit \
		--output-to-directory=docs/zxy \
		docs/tiles.mbtiles

.PHONY: tile_server
tile_server:
	http-server docs --cors true -p 9090

# charites serve port is 8080
.PHONY: charites_server
charites_server:
	charites serve style.yml
