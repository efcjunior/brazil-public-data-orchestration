# Integration testing

The integration smoke test verifies the first cross-service flow between `auth-api` and `bdi-api`.

## What the smoke test proves

1. `auth-api` starts and bootstraps the local administrator.
2. The administrator can log in with audience `bdi-api`.
3. The administrator can create a regular user.
4. The regular user can log in with audience `bdi-api`.
5. `bdi-api` accepts a valid token issued by `auth-api` for audience `bdi-api`.
6. `auth-api` can refresh the user's token.
7. `bdi-api` accepts the refreshed token.
8. `bdi-api` rejects a token issued for a different audience.

The smoke test calls `GET /api/v1/bdi/history` instead of `GET /api/v1/bdi/current` because a fresh local database may not have a current BDI snapshot yet. An empty history response is still enough to prove authorization and token validation.

## Run

Using published images:

```bash
docker compose up -d
./scripts/smoke-auth-bdi.sh
```

Using local source builds:

```bash
docker compose -f docker-compose.yml -f docker-compose.local-build.yml up --build -d
./scripts/smoke-auth-bdi.sh
```

## Configuration

The script reads these variables, with defaults matching `.env.example`:

| Variable | Default |
| --- | --- |
| `AUTH_BASE_URL` | `http://localhost:8080` |
| `BDI_BASE_URL` | `http://localhost:8081` |
| `ADMIN_EMAIL` | `admin@example.com` |
| `ADMIN_PASSWORD` | `local-admin-password` |
| `USER_EMAIL` | `bdi.user@example.com` |
| `USER_PASSWORD` | `local-user-password` |
| `VALID_AUDIENCE` | `bdi-api` |
| `INVALID_AUDIENCE` | `another-api` |

## Troubleshooting

If the smoke test fails, inspect logs:

```bash
docker compose logs --tail=200 auth-api
docker compose logs --tail=200 bdi-api
```

Common causes:

- `JWT_ISSUER` in `auth-api` does not match `AUTH_JWT_ISSUER` in `bdi-api`.
- `AUTH_JWKS_URI` in `bdi-api` cannot reach `auth-api` inside the Compose network.
- `JWT_ALLOWED_AUDIENCES` does not include `bdi-api`.
- host ports `8080` or `8081` are already in use.
