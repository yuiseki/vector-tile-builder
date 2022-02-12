# vector-tile-builder

## Requirements

- GNU make
- curl
- Docker

## Usage

You must edit `REGION` and `TILES_URL` value in `.env` file.

`REGION` is some string like the path of https://download.geofabrik.de/

```
cp .env.sapmle .env
```

Run `make`

```
make
```
