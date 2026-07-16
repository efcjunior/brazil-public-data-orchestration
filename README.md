# Brazil Public Data Orchestration

Local orchestration for Brazil public data services.

This repository does not own business code. It composes independent projects such as `auth-api`, `bdi-api`, and future public-data APIs so their integration can be exercised as one ecosystem.

## Current scope

Phase 9 focuses on local integration testing for:

- `auth-api`
- `bdi-api`
- `auth-mongo`
- `bdi-mongo`

The first smoke flow validates login, user creation, JWT audience/issuer configuration, refresh, and protected BDI access.

## Expected workspace layout

The default stack uses published Docker images from GitHub Container Registry.

For local source builds, this repository expects sibling project folders:

```text
applications/
  auth-api/
  bdi-api/
  brazil-public-data-orchestration/
```

## Quick start

Use the published images:

```bash
cp .env.example .env
docker compose up -d
./scripts/smoke-auth-bdi.sh
```

Services are exposed locally as:

| Service | URL |
| --- | --- |
| auth-api | `http://localhost:8080` |
| bdi-api | `http://localhost:8081` |
| auth MongoDB | `localhost:27018` |
| bdi MongoDB | `localhost:27019` |

## Local source build

When changing `auth-api` or `bdi-api` locally, run with the local-build override:

```bash
docker compose -f docker-compose.yml -f docker-compose.local-build.yml up --build -d
./scripts/smoke-auth-bdi.sh
```

The override builds:

- `../auth-api`
- `../bdi-api`

## Stop local stack

```bash
docker compose down
```

To remove local databases too:

```bash
docker compose down -v
```

## Documentation

- [Local development](docs/local-development.md)
- [Integration testing](docs/integration-testing.md)
