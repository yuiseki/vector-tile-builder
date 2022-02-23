# Build and Deploy OpenStreetMap vector tile maps on Raspberry Pi

## Setup Raspberry Pi

**Important Steps**:

- Write Raspberry Pi OS Lite **64-bit** to Boot storage
- Create empty file named `ssh` at `boot` drive
- Connect LAN cable to Raspberry Pi
- Connect power supply cable to Raspberry Pi
- Login to Raspberry Pi via SSH
  - `ssh pi@raspberrypi.local`
    - default password is `raspberry`
  - Enable SSH
    - `sudo raspi-config nonint do_ssh 1`

## Setup Docker

```bash
# Install Docker
sudo curl -fsSL https://get.docker.com | sudo bash
# add yourself to docker group
sudo gpasswd -a $(whoami) docker
# check docker group
getent group docker
# change group of docker.sock
sudo chgrp docker /var/run/docker.sock
# restart docker
sudo service docker restart
docker ps
```

If `docker ps` still shows error, try to restart Raspberry Pi.

## Get this repos

```bash
# Install git
sudo apt install git -y
git clone -b main --depth 1 https://github.com/yuiseki/vector-tile-builder.git
cd vector-tile-builder
```

## Copy `.env.local` to `.env`

```bash
cp .env.local .env
```

`.env.local` has written for Raspberry Pi.  
I recommend that in first time to make, you may leave `region` value.

## Try to run `make`

```
make
```

...It will done everything you want, If you meets requirements.

## Launch vector tile maps server

```
make start
```

## See your Raspberry Pi

http://raspberrypi.local/
