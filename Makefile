include .env

pbf = tmp/$(REGION)-latest.osm.pbf
mbtiles = tmp/region.mbtiles
tilejson = docs/tiles.json
stylejson = docs/style.json
zxy_metadata = docs/zxy/metadata.json

targets = \
	docker-build \
	$(pbf) \
	$(mbtiles) \
	$(tilejson) \
	$(zxy_metadata) \
	$(stylejson)

all: $(targets)

clean:
	sudo rm -rf tmp/zxy/*
	sudo rm -f tmp/region.mbtiles
	rm -rf docs/zxy/*
	rm -f docs/style.json
	rm -f docs/tiles.json

clean-all:
	docker rmi $(docker images | grep 'vector-tile-builder')
	sudo rm -rf tmp/*
	rm -rf docs/zxy/*
	rm -f docs/tiles.json

# Build the `vector-tile-builder` docker image if not exists, must important step of this Makefile
.PHONY: docker-build
docker-build:
	docker image inspect vector-tile-builder > /dev/null || docker build . -t vector-tile-builder

# Download OpenStreetMap data as Protocolbuffer Binary format file
$(pbf):
	mkdir -p $(@D)
	curl \
		--continue-at - \
		--output $(pbf) \
		https://download.geofabrik.de/$(REGION)-latest.osm.pbf

# Convert Protocolbuffer Binary format file to MBTiles format file
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

# Generate TileJSON format file from MBTiles format file
$(tilejson):
	mkdir -p $(@D)
	docker run \
		-it \
		--rm \
		--mount type=bind,source=$(CURDIR)/tmp,target=/tmp \
		vector-tile-builder \
			mbtiles2tilejson \
				/tmp/region.mbtiles \
				--url $(TILES_URL) > docs/tiles.json

# Split MBTiles format file to zxy orderd Protocolbuffer Binary format files
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

# Generate style.json from style.yml
$(stylejson):
	docker run \
		-it \
		--rm \
		--mount type=bind,source=$(CURDIR)/,target=/app \
		vector-tile-builder \
			charites build style.yml docs/style.json

# Initialize gh-pages branch
.PHONY: init-gh-pages
init-gh-pages:
	git checkout --orphan gh-pages
	git commit --allow-empty -m "empty commit"
	git push -u origin gh-pages
	git checkout main

# Publish ./docs to GitHub Pages, with ignoring .gitignore
.PHONY: gh-pages
gh-pages:
	sed -i '/docs/d' ./.gitignore
	git add .
	git commit -m "Edit .gitignore to publish"
	git push origin `git subtree split --prefix docs main`:gh-pages --force
	git reset HEAD~
	git checkout .gitignore

# Launch local server
.PHONY: start
start:
	docker run \
		-it \
		--rm \
		--mount type=bind,source=$(CURDIR)/docs,target=/app/docs \
		-p $(PORT):$(PORT) \
		vector-tile-builder \
			http-server \
				-p $(PORT) \
				docs
