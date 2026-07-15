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

This repository expects sibling project folders:

```text
applications/
  auth-api/
  bdi-api/
  brazil-public-data-orchestration/
```

Docker Compose builds the APIs from `../auth-api` and `../bdi-api`.

## Quick start

```bash
cp .env.example .env
docker compose up --build -d
./scripts/smoke-auth-bdi.sh
```

Services are exposed locally as:

| Service | URL |
| --- | --- |
| auth-api | `http://localhost:8080` |
| bdi-api | `http://localhost:8081` |
| auth MongoDB | `localhost:27018` |
| bdi MongoDB | `localhost:27019` |

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
