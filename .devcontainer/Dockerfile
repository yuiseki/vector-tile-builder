FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get -y upgrade && \
  apt-get -y install \
  sudo \
  git \
  curl \
  wget \
  make \
  tmux \
  htop \
  vim \
  jq

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
