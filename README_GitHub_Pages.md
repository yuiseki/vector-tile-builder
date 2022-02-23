# Build and Deploy OpenStreetMap vector tile maps on GitHub Actions and GitHub Pages

## Example

- https://github.com/yuiseki/vector-tile-builder-test
  - https://yuiseki.github.io/vector-tile-builder-test/

## Steps

- Click `Use this template`
- Decide name of your maps
- Edit `.env`
- Update GitHub Page settings of repository

## Click `Use this template` button of this repository

[![Image from Gyazo](https://i.gyazo.com/961462b0a684ae3fe8b862d67b9cc1d2.png)](https://gyazo.com/961462b0a684ae3fe8b862d67b9cc1d2)

Decide the name of repository of your new maps.  
This name will use the URL of the GitHub Pages.

## Edit and commit `.env` on GitHub

You MUST edit ONLY `REGION`.  
When you commit changes to `main` branch, GitHub Actions will automatically runs with new `.env` value.

NOTE: **GitHub Pages has 1GB size limits.**  
So you MUST NOT choose very large `REGION`.

You can ignore `TILES_URL` and `PORT` values when you deploy vector tile maps to GitHub Pages.  
Those value will only use when launch local vector tile server.

## Update repository settings

Don't forget: You MUST change settings of your repository about GitHub Pages.  
Choose `gh-pages` branch and save.

[![Image from Gyazo](https://i.gyazo.com/6632ad1298122502b18cfc4d151b330a.png)](https://gyazo.com/6632ad1298122502b18cfc4d151b330a)

## See your GitHub Pages
