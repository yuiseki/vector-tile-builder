include .env

pbf = tmp/osm/$(REGION)-latest.osm.pbf
mbtiles = tmp/region.mbtiles
tilejson = docs/tiles.json
stylejson = docs/style.json
zxy_metadata = docs/zxy/metadata.json

targets = \
	docs/openmaptiles/fonts/Open\ Sans\ Bold/0-255.pbf \
	docs/openmaptiles/fonts/Open\ Sans\ Italic/0-255.pbf \
	docs/openmaptiles/fonts/Open\ Sans\ Regular/0-255.pbf \
	$(pbf) \
	$(mbtiles) \
	$(tilejson) \
	$(zxy_metadata) \
	$(stylejson)


all: $(targets)

clean:
	sudo chmod 777 -R tmp
	rm -rf docs/zxy/*
	rm -f docs/style.json
	rm -f docs/tiles.json

clean-all:
	rm -f tmp/region.mbtiles
	rm -rf tmp/zxy/*
	rm -rf docs/zxy/*
	rm -f docs/tiles.json
	rm -f docs/style.json
	rm -rf docs/openmaptiles/fonts/Open\ Sans\ Bold
	rm -rf docs/openmaptiles/fonts/Open\ Sans\ Italic
	rm -rf docs/openmaptiles/fonts/Open\ Sans\ Regular
	docker rmi $(docker images | grep 'vector-tile-builder')

# Pull `yuiseki/vector-tile-builder` docker image if not exists
.PHONY: docker-pull
docker-pull:
	docker image inspect yuiseki/vector-tile-builder:latest > /dev/null || docker pull yuiseki/vector-tile-builder:latest

# Build `yuiseki/vector-tile-builder` docker image if not exists
.PHONY: docker-build
docker-build:
	docker image inspect yuiseki/vector-tile-builder:latest > /dev/null || docker build . -t yuiseki/vector-tile-builder:latest

# Push `yuiseki/vector-tile-builder` docker image to docker hub
# MEMO: require `docker login`
.PHONY: docker-push
docker-push:
	docker push yuiseki/vector-tile-builder:latest

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
		-i \
		--rm \
		--mount type=bind,source=$(CURDIR)/tmp,target=/tmp \
		yuiseki/vector-tile-builder \
			tilemaker \
				--threads 3 \
				--skip-integrity \
				--input /$(pbf) \
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

# Generate style.json from style.yml
$(stylejson):
	docker run \
		-i \
		--rm \
		--mount type=bind,source=$(CURDIR)/,target=/app \
		yuiseki/vector-tile-builder \
			charites build style.yml docs/style.json
	sed "s|http://localhost:5000/|$(BASE_PATH)|g" -i docs/style.json

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
