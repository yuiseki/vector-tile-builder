include .env

pbf = tmp/$(REGION)-latest.osm.pbf
mbtiles = tmp/region.mbtiles
tilejson = docs/tiles.json
zxy_metadata = docs/zxy/metadata.json

targets = \
	docker-build \
	$(pbf) \
	$(mbtiles) \
	$(tilejson) \
	$(zxy_metadata)

all: $(targets)

clean:
	docker rmi $(docker images | grep 'vector-tile-builder')
	rm -rf tmp/*
	rm -rf docs/zxy/*
	rm -f docs/tiles.json

.PHONY: docker-build
docker-build:
	docker image inspect vector-tile-builder || docker build . -t vector-tile-builder

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
		-it \
		--rm \
		--mount type=bind,source=$(CURDIR)/tmp,target=/tmp \
		vector-tile-builder \
			tilemaker \
				--threads 0 \
				--input /$(pbf) \
				--output /$(mbtiles)

$(tilejson):
	mkdir -p $(@D)
	docker run \
		-it \
		--rm \
		--mount type=bind,source=$(CURDIR)/tmp,target=/tmp \
		vector-tile-builder \
			mbtiles2tilejson \
				/tmp/region.mbtiles \
				--url $(GITHUB_PAGES)zxy > /tmp/tiles.json
	cp tmp/tiles.json docs/

# Split MBTiles Format file to zxy orderd Protocolbuffer Binary Format files
$(zxy_metadata):
	mkdir -p $(@D)
	docker run \
		-it \
		--rm \
		--mount type=bind,source=$(CURDIR)/tmp,target=/tmp \
		vector-tile-builder \
			tile-join \
				--force \
				--no-tile-compression \
				--no-tile-size-limit \
				--no-tile-stats \
				--output-to-directory=/tmp/zxy \
				/$(mbtiles)
	cp -r tmp/zxy docs/
