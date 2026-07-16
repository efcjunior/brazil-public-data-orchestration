# Local development

This repository starts the Brazil public data ecosystem as separate services.

There are two supported run modes:

- default mode: runs published Docker images from GitHub Container Registry;
- local-build mode: builds `auth-api` and `bdi-api` from sibling folders.

## Why separate MongoDB services?

`auth-api` and `bdi-api` own different data:

- `auth-api`: users, refresh tokens, JWT signing keys/configuration.
- `bdi-api`: BDI snapshots and BDI refresh jobs.

Using separate MongoDB containers makes that boundary visible during local development.

## Internal service URLs

Inside the Compose network:

| Service | Internal URL |
| --- | --- |
| auth-api | `http://auth-api:8080` |
| bdi-api | `http://bdi-api:8080` |

`auth-api` issues JWTs with issuer:

```text
http://auth-api:8080
```

`bdi-api` validates that same issuer and reads JWKS from:

```text
http://auth-api:8080/api/v1/auth/jwks
```

This is why the internal URL differs from the host URL `http://localhost:8080`.
The host URL is only how your terminal/browser reaches the service.


## MongoDB configuration

The Compose file passes both `MONGODB_URI` and `SPRING_MONGODB_URI` to the APIs. `MONGODB_URI` keeps compatibility with each service's local profile placeholders, while `SPRING_MONGODB_URI` pins the effective Spring Boot MongoDB connection string used inside the orchestration stack.

## Start

### Using published images

```bash
cp .env.example .env
docker compose up -d
```

By default, the stack uses:

```text
ghcr.io/efcjunior/auth-api:1.0.0
ghcr.io/efcjunior/bdi-api:1.0.1
```

You can override these in `.env`:

```env
AUTH_API_IMAGE=ghcr.io/efcjunior/auth-api:1.0.0
BDI_API_IMAGE=ghcr.io/efcjunior/bdi-api:1.0.1
```

### Building local source code

Use this mode when you are changing `../auth-api` or `../bdi-api` and want Compose to rebuild the images from your local workspace:

```bash
docker compose -f docker-compose.yml -f docker-compose.local-build.yml up --build -d
```

## Inspect logs

```bash
docker compose logs -f auth-api
docker compose logs -f bdi-api
```

## Stop

```bash
docker compose down
```
