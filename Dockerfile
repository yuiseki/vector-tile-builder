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
  python3 \
  build-essential \
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

WORKDIR /tmp

RUN git clone https://github.com/systemed/tilemaker &&\
  cd tilemaker; make -j4 LDFLAGS="-latomic"; make install; cd .. &&\
  rm -rf tilemaker

RUN git clone https://github.com/mapbox/tippecanoe &&\
  cd tippecanoe; make -j4 LDFLAGS="-latomic"; make install; cd .. &&\
  rm -rf tippecanoe

RUN curl -Ls https://deb.nodesource.com/setup_16.x | bash
RUN apt-get update && apt-get install -y nodejs \
      && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . /app

CMD ["/bin/bash"]
