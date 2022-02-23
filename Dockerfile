FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get -y upgrade && \
  apt-get -y install \
  sudo \
  curl \
  git \
  jq \
  osmium-tool \
  build-essential \
  gcc \
  g++ \
  make \
  python3 \
  python-is-python3 \
  sqlite3 \
  libsqlite3-dev \
  zlib1g-dev \
  # dependencies for tilemaker
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

WORKDIR /app

RUN curl -Ls https://deb.nodesource.com/setup_16.x | bash
RUN apt-get update && apt-get install -y nodejs \
      && rm -rf /var/lib/apt/lists/*

RUN npm i -g http-server
RUN npm i -g mbtiles2tilejson
RUN npm i -g @unvt/charites

RUN git clone --depth 1 https://github.com/systemed/tilemaker &&\
  cd tilemaker; make -j$(nproc) LDFLAGS="-latomic"; make install; cd .. &&\
  cp tilemaker/resources/config-openmaptiles.json ./config.json &&\
  cp tilemaker/resources/process-openmaptiles.lua ./process.lua &&\
  rm -rf tilemaker

RUN git clone --depth 1 https://github.com/mapbox/tippecanoe &&\
  cd tippecanoe; make -j$(nproc) LDFLAGS="-latomic"; make install; cd .. &&\
  rm -rf tippecanoe

CMD ["/bin/bash"]
