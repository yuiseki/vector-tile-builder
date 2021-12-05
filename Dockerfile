FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get -y upgrade && \
  apt-get -y install \
  sudo \
  curl \
  git \
  build-essential \
  sqlite3 \
  libsqlite3-dev \
  zlib1g-dev \
  jq \
  osmium-tool

WORKDIR /tmp

RUN git clone https://github.com/mapbox/tippecanoe &&\
  cd tippecanoe; make -j3 LDFLAGS="-latomic"; make install; cd .. &&\
  rm -rf tippecanoe

RUN curl -Ls https://deb.nodesource.com/setup_16.x | bash
RUN apt-get update && apt-get install -y nodejs \
      && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/unvt/charites.git && \
  cd charites && \
  npm ci && \
  npm run build && \
  npm i -g .

RUN npm i -g http-server

WORKDIR /app

COPY . /app

CMD ["/bin/bash"]
