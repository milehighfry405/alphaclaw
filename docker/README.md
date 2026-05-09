# alphaclaw Docker build

Build context must be this directory, not the repo root:

```bash
docker build -t alphaclaw docker/
```

Do NOT run `docker build -f docker/Dockerfile .` — that copies the wrong package.json.
