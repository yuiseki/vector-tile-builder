FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update

RUN apt-get -y install \
    sudo \
    curl \
    git \
    vim \
    jq \
    sqlite3

RUN apt-get -y install \
    build-essential \
    gcc \
    g++ \
    make \
    python3 \
    python-is-python3 \
    libsqlite3-dev \
    zlib1g-dev

RUN apt-get -y install \
    gdal-bin \
    osm2pgsql \
    osmosis \
    osmium-tool \
    osmctools

WORKDIR /app

# dependencies for tilemaker
RUN apt-get -y install \
    libboost-dev \
    libboost-filesystem-dev \
    libboost-iostreams-dev \
    libboost-program-options-dev \
    libboost-system-dev \
    liblua5.1-0-dev \
    libprotobuf-dev \
    libshp-dev \
    protobuf-compiler \
    rapidjson-dev

RUN git clone --depth 1 https://github.com/systemed/tilemaker &&\
  cd tilemaker; make -j3 LDFLAGS="-latomic"; make install; cd .. &&\
  cp tilemaker/resources/config-openmaptiles.json ./config.json &&\
  cp tilemaker/resources/process-openmaptiles.lua ./process.lua &&\
  rm -rf tilemaker

RUN git clone --depth 1 https://github.com/felt/tippecanoe &&\
  cd tippecanoe; make -j3 LDFLAGS="-latomic"; make install &&\
  cd ..; rm -rf tippecanoe

RUN curl -Ls https://deb.nodesource.com/setup_18.x | bash
RUN apt-get update && apt-get install -y nodejs \
      && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN npm i -g http-server
RUN npm i -g mbtiles2tilejson
RUN npm i -g osmtogeojson
RUN npm i -g geojson2poly
RUN git clone --depth 1 https://github.com/unvt/charites &&\
  cd charites; npm ci; npm run build; npm install -g .

WORKDIR /app

CMD ["/bin/bash"]
