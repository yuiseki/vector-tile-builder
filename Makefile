include .env

pbf = tmp/$(REGION)-latest.osm.pbf
mbtiles = tmp/region.mbtiles
tilejson = docs/tiles.json
zxy_metadata = docs/zxy/metadata.json

targets = \
	$(pbf) \
	$(mbtiles) \
	$(tilejson) \
	$(zxy_metadata)

all: $(targets)

clean:
	rm -rf tmp/*
	rm -rf docs/zxy/*
	rm -f docs/tiles.json


# Download OpenStreetMap data as Protocolbuffer Binary Format file
$(pbf):
	mkdir -p $(@D)
	curl \
		--continue-at - \
		--output $(pbf) \
		https://download.geofabrik.de/$(REGION)-latest.osm.pbf

# Convert Protocolbuffer Binary Format file to MBTiles format file
$(mbtiles):
	mkdir -p $(@D)
	docker run \
		--rm \
		--mount type=bind,source=$(CURDIR)/tmp,target=/tmp \
		tilemaker-center \
			--input /$(pbf) \
			--output /$(mbtiles)

$(tilejson):
	mbtiles2tilejson tmp/region.mbtiles --url $(GITHUB_PAGES) > $@

# Split MBTiles Format file to zxy orderd Protocolbuffer Binary Format files
$(zxy_metadata):
	mkdir -p $(@D)
	docker run \
		-it \
		--rm \
		--mount type=bind,source=$(CURDIR)/tmp,target=/tmp \
		tippecanoe \
			tile-join \
				--force \
				--no-tile-compression \
				--no-tile-size-limit \
				--no-tile-stats \
				--output-to-directory=/tmp/zxy \
				/$(mbtiles)
	cp -r tmp/zxy docs/zxy
