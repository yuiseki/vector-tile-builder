# vector-tile-builder

## Requirements

- git
- curl
- GNU sed
- GNU make
- Docker

## Create vector tile maps on GitHub Pages

### Click `Use this template` button of this repository

Decide name of your new maps repository.

### `git clone` your repository

### Copy and edit `.env`

```
cp .env.sample .env
```

You must edit `REGION` and `TILES_URL` value in `.env` file.

`REGION` is some string of the path of https://download.geofabrik.de/
`TILES_URL` is determine by your GitHub Pages settings.

Note that: GitHub Pages has 1GB size limits.
So you do not choose large `REGION`.

You can ignore `PORT` value when you deploy vector tile maps to GitHub Pages.

### Run `make clean` and `make`

Require `make clean` to remove sample vector tiles on `./docs`

```
make clean
make
```

### Create `gh-pages` branch

```
make gh-pages
git push
```

### See GitHub Pages
