include .env

region_pbf = tmp/osm/$(REGION)-latest.osm.pbf
admin_osmjson = tmp/$(ADMIN).osm.json
admin_geojson = tmp/$(ADMIN).geojson
admin_poly = tmp/$(ADMIN).poly
admin_pbf = tmp/$(ADMIN).pbf
mbtiles = tmp/region.mbtiles
tilejson = docs/tiles.json
stylejson = docs/style.json
zxy_metadata = docs/zxy/metadata.json
pmtiles = tmp/region.pmtiles
pmtiles_docs = docs/region.pmtiles
pmtiles_stylejson = docs/style.pmtiles.json

targets = \
	docs/openmaptiles/fonts/Open\ Sans\ Bold/0-255.pbf \
	docs/openmaptiles/fonts/Open\ Sans\ Italic/0-255.pbf \
	docs/openmaptiles/fonts/Open\ Sans\ Regular/0-255.pbf \
	$(region_pbf) \
	$(admin_osmjson) \
	$(admin_geojson) \
	$(admin_poly) \
	$(admin_pbf) \
	$(mbtiles) \
	$(tilejson) \
	$(zxy_metadata) \
	$(stylejson) \
	$(pmtiles) \
	$(pmtiles_docs) \
	$(pmtiles_stylejson)

all: $(targets)

clean:
	sudo chmod 777 -R tmp
	rm -rf docs/zxy/*
	rm -f $(mbtiles)
	rm -f $(stylejson)
	rm -f $(tilejson)
	rm -f $(pmtiles)
	rm -f $(pmtiles_docs)
	rm -f $(pmtiles_stylejson)

clean-all: clean
	sudo chmod 777 -R tmp
	rm -f $(admin_osmjson)
	rm -f $(admin_geojson)
	rm -f $(admin_poly)
	rm -f $(admin_pbf)
	rm -f $(mbtiles)
	rm -f $(tilejson)
	rm -f $(stylejson)
	rm -f $(pmtiles)
	rm -f $(pmtiles_docs)
	rm -f $(pmtiles_stylejson)
	rm -rf tmp/zxy/*
	rm -rf docs/zxy/*
	rm -rf docs/openmaptiles/fonts/Open\ Sans\ Bold
	rm -rf docs/openmaptiles/fonts/Open\ Sans\ Italic
	rm -rf docs/openmaptiles/fonts/Open\ Sans\ Regular


#
# docker
#
# Pull `yuiseki/vector-tile-builder` docker image if not exists
.PHONY: docker-pull
docker-pull:
	docker image inspect yuiseki/vector-tile-builder:latest > /dev/null || docker pull yuiseki/vector-tile-builder:latest
	docker image inspect yuiseki/go-pmtiles:latest > /dev/null || docker pull yuiseki/go-pmtiles:latest

.PHONY: docker-pull-all
docker-pull-all:
	docker image inspect maptiler/tileserver-gl:latest > /dev/null || docker pull maptiler/tileserver-gl:latest

# Build `yuiseki/vector-tile-builder` docker image if not exists
.PHONY: docker-build
docker-build:
	docker image inspect yuiseki/vector-tile-builder:latest > /dev/null || docker build . -t yuiseki/vector-tile-builder:latest
	docker image inspect yuiseki/go-pmtiles:latest > /dev/null || docker build -t yuiseki/go-pmtiles:latest github.com/protomaps/go-pmtiles#main

# Push `yuiseki/vector-tile-builder` docker image to docker hub
# MEMO: require `docker login`
.PHONY: docker-push
docker-push:
	docker push yuiseki/vector-tile-builder:latest
	docker push yuiseki/go-pmtiles:latest

# Download OpenStreetMap data as Protocolbuffer Binary format file
$(region_pbf):
	mkdir -p $(@D)
	curl \
		--continue-at - \
		--output $(region_pbf) \
		https://download.geofabrik.de/$(REGION)-latest.osm.pbf

QUERY = data=[out:json][timeout:30000]; relation["name:en"="$(ADMIN)"]; out geom;
$(admin_osmjson):
	curl 'https://overpass-api.de/api/interpreter' \
		--data-urlencode '$(QUERY)' > $(admin_osmjson)

$(admin_geojson):
	docker run \
		-i \
		--rm \
		--mount type=bind,source=$(CURDIR)/tmp,target=/tmp \
		yuiseki/vector-tile-builder \
			bash -c "\
				osmtogeojson /$(admin_osmjson) > /$(admin_geojson)\
			"

$(admin_poly):
	docker run \
		-i \
		--rm \
		--mount type=bind,source=$(CURDIR)/tmp,target=/tmp \
		yuiseki/vector-tile-builder \
			geojson2poly /$(admin_geojson) /$(admin_poly)

$(admin_pbf):
	docker run \
		-i \
		--rm \
		--mount type=bind,source=$(CURDIR)/tmp,target=/tmp \
		yuiseki/vector-tile-builder \
			osmconvert /$(region_pbf) -B="/$(admin_poly)" --complete-ways -o=/$(admin_pbf)


#
# tilemaker
#
# Convert Protocolbuffer Binary format file to MBTiles format file
$(mbtiles):
	mkdir -p $(@D)
	docker run \
		-i \
		--rm \
		--mount type=bind,source=$(CURDIR)/tmp,target=/tmp \
		yuiseki/vector-tile-builder \
			tilemaker \
				--threads 3 \
				--skip-integrity \
				--input /$(region_pbf) \
				--output /$(mbtiles)


# Generate TileJSON format file from MBTiles format file
$(tilejson):
	mkdir -p $(@D)
	docker run \
		-i \
		--rm \
		--mount type=bind,source=$(CURDIR)/tmp,target=/tmp \
		yuiseki/vector-tile-builder \
			mbtiles2tilejson \
				/tmp/region.mbtiles \
				--url $(TILES_URL) > docs/tiles.json
	sed "s|http://localhost:5000/|$(BASE_PATH)|g" -i docs/tiles.json


#
# tippecanoe
#
# Split MBTiles format file to zxy orderd Protocolbuffer Binary format files
$(zxy_metadata):
	mkdir -p $(@D)
	docker run \
		-i \
		--rm \
		--mount type=bind,source=$(CURDIR)/tmp,target=/tmp \
		yuiseki/vector-tile-builder \
			tile-join \
				--force \
				--no-tile-compression \
				--no-tile-size-limit \
				--no-tile-stats \
				--output-to-directory=/tmp/zxy \
				/$(mbtiles)
	cp -r tmp/zxy docs/


#
# charites
#
# Generate style.json from style.yml
$(stylejson):
	docker run \
		-i \
		--rm \
		--mount type=bind,source=$(CURDIR)/,target=/app \
		yuiseki/vector-tile-builder \
			charites build style.yml docs/style.json
	sed "s|http://localhost:5000/|$(BASE_PATH)|g" -i docs/style.json


#
# go-pmtiles
#
# Convert MBTiles format file to PMtiles format file
$(pmtiles):
	mkdir -p $(@D)
	docker run \
		-i \
		--rm \
		--mount type=bind,source=$(CURDIR)/tmp,target=/tmp \
		yuiseki/go-pmtiles \
			convert /$(mbtiles) /$(pmtiles)

$(pmtiles_docs): $(pmtiles)
	cp -f $(pmtiles) $(pmtiles_docs)

$(pmtiles_stylejson): $(stylejson)
	cp -f $(stylejson) $(pmtiles_stylejson)
	sed "s|$(BASE_PATH)tile.json|pmtiles://$(BASE_PATH)region.pmtiles|g" -i $(pmtiles_stylejson)


docs/openmaptiles/fonts/Open\ Sans\ Bold/0-255.pbf:
	cd docs/openmaptiles/fonts && unzip Open\ Sans\ Bold.zip
	chmod 777 -R docs/openmaptiles/fonts

docs/openmaptiles/fonts/Open\ Sans\ Italic/0-255.pbf:
	cd docs/openmaptiles/fonts && unzip Open\ Sans\ Italic.zip
	chmod 777 -R docs/openmaptiles/fonts

docs/openmaptiles/fonts/Open\ Sans\ Regular/0-255.pbf:
	cd docs/openmaptiles/fonts && unzip Open\ Sans\ Regular.zip
	chmod 777 -R docs/openmaptiles/fonts

# Launch local tile server
.PHONY: start
start:
	docker run \
		-it \
		--rm \
		--mount type=bind,source=$(CURDIR)/docs,target=/app/docs \
		-p $(PORT):$(PORT) \
		yuiseki/vector-tile-builder \
			http-server \
				-p $(PORT) \
				docs

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

# Configure Raspberry Pi as Wi-Fi AP
# need to call with sudo
# `sudo make build-wifi-ap`
.PHONY: build-wifi-ap
build-wifi-ap:
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo "Starting to configure Wi-Fi AP..."
	cat /etc/rpi-issue
	apt update
	apt upgrade -y
	DEBIAN_FRONTEND=noninteractive \
		apt install -y \
			hostapd \
			dnsmasq \
			netfilter-persistent \
			iptables-persistent
	systemctl unmask hostapd
	systemctl enable hostapd
	cp conf/etc/dhcpcd.conf /etc/dhcpcd.conf
	cp conf/etc/dnsmasq.conf /etc/dnsmasq.conf
	cp conf/etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf
	cp conf/etc/sysctl.d/routed-ap.conf /etc/sysctl.d/routed-ap.conf
	iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
	netfilter-persistent save
	rfkill unblock wlan
	systemctl reboot
