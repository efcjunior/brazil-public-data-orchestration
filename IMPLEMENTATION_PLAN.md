# Brazil Public Data Orchestration Implementation Plan

## Purpose

Provide local and future deployment orchestration for Brazil public data services.

This repository coordinates independent projects. It should not contain service business logic.

## Current services

- `auth-api`: authentication, users, refresh tokens, JWT issuing, JWKS.
- `bdi-api`: BDI public-data API and BDI resource-server validation.

## Implementation progress

- [x] Phase 1 — Local auth + BDI integration harness
- [ ] Phase 2 — Additional public-data API onboarding template
- [ ] Phase 3 — Frontend shell/microfrontend local composition
- [ ] Phase 4 — Observability and operational tooling
- [ ] Phase 5 — CI smoke integration workflow

## Phase 1 — Local auth + BDI integration harness

### Deliverables

- Docker Compose stack for `auth-api`, `bdi-api`, and their MongoDB databases.
- Environment example for local integration.
- Smoke script for login, user creation, refresh, valid audience, and invalid audience checks.
- Documentation explaining local service URLs and the JWT issuer/JWKS relationship.

### Completion gate

- `docker compose config` succeeds.
- `scripts/smoke-auth-bdi.sh` validates the auth-to-BDI flow against the local stack.
