#!/usr/bin/env bash
set -euo pipefail

AUTH_BASE_URL="${AUTH_BASE_URL:-http://localhost:8080}"
BDI_BASE_URL="${BDI_BASE_URL:-http://localhost:8081}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-local-admin-password}"
USER_EMAIL="${USER_EMAIL:-bdi.user@example.com}"
USER_PASSWORD="${USER_PASSWORD:-local-user-password}"
VALID_AUDIENCE="${VALID_AUDIENCE:-bdi-api}"
INVALID_AUDIENCE="${INVALID_AUDIENCE:-another-api}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-120}"

LAST_STATUS=""
LAST_BODY=""

log() {
  printf '[smoke-auth-bdi] %s\n' "$*"
}

fail() {
  printf '[smoke-auth-bdi] ERROR: %s\n' "$*" >&2
  if [[ -n "${LAST_STATUS}" || -n "${LAST_BODY}" ]]; then
    printf '[smoke-auth-bdi] Last HTTP status: %s\n' "${LAST_STATUS:-n/a}" >&2
    printf '[smoke-auth-bdi] Last HTTP body:\n%s\n' "${LAST_BODY:-<empty>}" >&2
  fi
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command '$1' was not found"
}

json_string() {
  python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"
}

json_field() {
  python3 -c 'import json,sys; print(json.load(sys.stdin)[sys.argv[1]])' "$1"
}

request() {
  local method="$1"
  local url="$2"
  local body="${3:-}"
  local token="${4:-}"
  local response_file
  response_file="$(mktemp)"

  local args=(-sS -o "${response_file}" -w '%{http_code}' -X "${method}" "${url}")
  if [[ -n "${body}" ]]; then
    args+=(-H 'Content-Type: application/json' --data "${body}")
  fi
  if [[ -n "${token}" ]]; then
    args+=(-H "Authorization: Bearer ${token}")
  fi

  LAST_STATUS="$(curl "${args[@]}")"
  LAST_BODY="$(cat "${response_file}")"
  rm -f "${response_file}"
}

expect_status() {
  local expected="$1"
  local context="$2"
  if [[ "${LAST_STATUS}" != "${expected}" ]]; then
    fail "${context}: expected HTTP ${expected}, got ${LAST_STATUS}"
  fi
}

wait_for_health() {
  local name="$1"
  local url="$2"
  local start
  start="$(date +%s)"

  log "Waiting for ${name} at ${url}"
  while true; do
    if request GET "${url}" && [[ "${LAST_STATUS}" == "200" ]]; then
      log "${name} is healthy"
      return 0
    fi

    if (( $(date +%s) - start >= TIMEOUT_SECONDS )); then
      fail "Timed out waiting for ${name} health"
    fi
    sleep 2
  done
}

login() {
  local email="$1"
  local password="$2"
  local audience="$3"
  local payload
  payload="{\"email\":$(json_string "${email}"),\"password\":$(json_string "${password}"),\"audience\":$(json_string "${audience}")}"
  request POST "${AUTH_BASE_URL}/api/v1/auth/login" "${payload}"
  expect_status 200 "login ${email} for audience ${audience}"
}

refresh() {
  local refresh_token="$1"
  local audience="$2"
  local payload
  payload="{\"refreshToken\":$(json_string "${refresh_token}"),\"audience\":$(json_string "${audience}")}"
  request POST "${AUTH_BASE_URL}/api/v1/auth/refresh" "${payload}"
  expect_status 200 "refresh token for audience ${audience}"
}

create_user_if_needed() {
  local admin_token="$1"
  local payload
  payload="{\"email\":$(json_string "${USER_EMAIL}"),\"password\":$(json_string "${USER_PASSWORD}"),\"roles\":[\"USER\"],\"enabled\":true}"
  request POST "${AUTH_BASE_URL}/api/v1/admin/users" "${payload}" "${admin_token}"

  case "${LAST_STATUS}" in
    201)
      log "Created integration user ${USER_EMAIL}"
      ;;
    409)
      log "Integration user ${USER_EMAIL} already exists; continuing"
      ;;
    *)
      fail "create integration user: expected HTTP 201 or 409, got ${LAST_STATUS}"
      ;;
  esac
}

assert_bdi_history_status() {
  local token="$1"
  local expected="$2"
  local context="$3"
  request GET "${BDI_BASE_URL}/api/v1/bdi/history" "" "${token}"
  expect_status "${expected}" "${context}"
}

require_command curl
require_command python3

log "Starting auth-api + bdi-api smoke test"
wait_for_health auth-api "${AUTH_BASE_URL}/actuator/health"
wait_for_health bdi-api "${BDI_BASE_URL}/actuator/health"

log "Checking that bdi-api protects BDI history without a token"
request GET "${BDI_BASE_URL}/api/v1/bdi/history"
expect_status 401 "BDI history without token"

log "Logging in bootstrap administrator"
login "${ADMIN_EMAIL}" "${ADMIN_PASSWORD}" "${VALID_AUDIENCE}"
admin_access_token="$(printf '%s' "${LAST_BODY}" | json_field accessToken)"

log "Creating or reusing regular integration user"
create_user_if_needed "${admin_access_token}"

log "Logging in regular user for valid audience ${VALID_AUDIENCE}"
login "${USER_EMAIL}" "${USER_PASSWORD}" "${VALID_AUDIENCE}"
user_access_token="$(printf '%s' "${LAST_BODY}" | json_field accessToken)"
user_refresh_token="$(printf '%s' "${LAST_BODY}" | json_field refreshToken)"

log "Calling bdi-api with valid user token"
assert_bdi_history_status "${user_access_token}" 200 "BDI history with valid user token"

log "Refreshing user token through auth-api"
refresh "${user_refresh_token}" "${VALID_AUDIENCE}"
refreshed_access_token="$(printf '%s' "${LAST_BODY}" | json_field accessToken)"

log "Calling bdi-api with refreshed user token"
assert_bdi_history_status "${refreshed_access_token}" 200 "BDI history with refreshed user token"

log "Logging in with invalid resource audience ${INVALID_AUDIENCE}"
login "${USER_EMAIL}" "${USER_PASSWORD}" "${INVALID_AUDIENCE}"
wrong_audience_token="$(printf '%s' "${LAST_BODY}" | json_field accessToken)"

log "Checking that bdi-api rejects the wrong audience token"
assert_bdi_history_status "${wrong_audience_token}" 401 "BDI history with wrong audience token"

log "Smoke test completed successfully"
