# Traefik

## Copy traefik assets to your repository

```bash
cp -r ../sparrow/templates/traefik ./traefik
```

## Add traefik environment variables to `Github secrets`, `example.env` and `.env`

```ini
TLS_EMAIL=<replaced-in-deployment>
```

## Include traefik in compose files

### `compose.yaml`
```yaml
include:
  - path:
    - traefik/compose.yaml
    - traefik/compose.override.yaml
```

### `compose.production.yaml`
```yaml
include:
  - path:
    - traefik/compose.yaml
```
