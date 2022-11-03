FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get -y upgrade && \
  apt-get -y install \
  sudo \
  curl \
  git \
  vim \
  jq \
  sqlite3 \
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
  rapidjson-dev \
  libgeos-dev libgeos++-dev libproj-dev gdal-bin libmapnik-dev mapnik-utils python3-mapnik python3-psycopg2

WORKDIR /app

RUN curl -Ls https://deb.nodesource.com/setup_18.x | bash
RUN apt-get update && apt-get install -y nodejs \
      && rm -rf /var/lib/apt/lists/*

RUN npm i -g http-server
RUN npm i -g mbtiles2tilejson
RUN git clone --depth -1 https://github.com/unvt/charites &&\
  cd charites; npm ci; npm run build; npm install -g .

RUN git clone --depth 1 https://github.com/systemed/tilemaker &&\
  cd tilemaker; make -j3 LDFLAGS="-latomic"; make install; cd .. &&\
  cp tilemaker/resources/config-openmaptiles.json ./config.json &&\
  cp tilemaker/resources/process-openmaptiles.lua ./process.lua &&\
  rm -rf tilemaker

RUN git clone --depth 1 https://github.com/mapbox/tippecanoe &&\
  cd tippecanoe; make -j3 LDFLAGS="-latomic"; make install; cd .. &&\
  rm -rf tippecanoe

RUN useradd -m user

ARG NONROOT_USER=user
RUN curl -fsSL https://get.docker.com | sh
RUN echo "#!/bin/sh\n\
    sudoIf() { if [ \"\$(id -u)\" -ne 0 ]; then sudo \"\$@\"; else \"\$@\"; fi }\n\
    SOCKET_GID=\$(stat -c '%g' /var/run/docker.sock) \n\
    if [ \"${SOCKET_GID}\" != '0' ]; then\n\
        if [ \"\$(cat /etc/group | grep :\${SOCKET_GID}:)\" = '' ]; then sudoIf groupadd --gid \${SOCKET_GID} docker-host; fi \n\
        if [ \"\$(id ${NONROOT_USER} | grep -E \"groups=.*(=|,)\${SOCKET_GID}\(\")\" = '' ]; then sudoIf usermod -aG \${SOCKET_GID} ${NONROOT_USER}; fi\n\
    fi\n\
    exec \"\$@\"" > /usr/local/share/docker-init.sh \
    && chmod +x /usr/local/share/docker-init.sh

USER user

ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]

CMD [ "sleep", "infinity" ]
