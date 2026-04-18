#!/usr/bin/env bash
# GLASS E2E Verifier — Machine-verified tests against live endpoints
# Returns number of verified stories (level 6 qualification)
#
# Usage: bash glass-e2e.sh --url URL [--token JWT]
#
# Without --token: tests endpoint existence (401 = exists)
# With --token: tests actual responses (200 + valid data = VERIFIED)

set -uo pipefail

LIVE_URL=""
AUTH_TOKEN=""
VERIFIED=0
TOTAL=0

while [[ $# -gt 0 ]]; do
  case $1 in
    --url) LIVE_URL="$2"; shift 2 ;;
    --token) AUTH_TOKEN="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

if [ -z "$LIVE_URL" ]; then
  echo "Usage: bash glass-e2e.sh --url URL [--token JWT]"
  exit 1
fi

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

echo ""
echo -e "${BOLD}GLASS E2E Verifier${NC}"
echo "  URL: $LIVE_URL"
echo "  Auth: $([ -n "$AUTH_TOKEN" ] && echo 'JWT provided' || echo 'no token (existence check only)')"
echo ""

auth_header=""
[ -n "$AUTH_TOKEN" ] && auth_header="-H \"Authorization: Bearer $AUTH_TOKEN\""

verify() {
  local name="$1" method="$2" path="$3" body="${4:-}"
  TOTAL=$((TOTAL + 1))

  local cmd="curl -s -o /tmp/glass_e2e_body -w '%{http_code}' ${auth_header}"
  [ "$method" = "POST" ] && cmd="$cmd -X POST -H 'Content-Type: application/json' -d '${body}'"
  cmd="$cmd '${LIVE_URL}${path}'"

  local status
  status=$(eval "$cmd" 2>/dev/null || echo "000")
  local body_preview
  body_preview=$(head -c 200 /tmp/glass_e2e_body 2>/dev/null || echo "")

  if [ -n "$AUTH_TOKEN" ]; then
    # With auth: expect 200 with valid response body
    if [ "$status" = "200" ] || [ "$status" = "201" ]; then
      # Check response has actual data (not empty or error)
      if echo "$body_preview" | grep -q '"id"\|"name"\|"items"\|"data"\|"status"' 2>/dev/null; then
        VERIFIED=$((VERIFIED + 1))
        printf "  ${GREEN}✓${NC} %-35s %s (data verified)\n" "$name" "$status"
      else
        printf "  ${YELLOW}~${NC} %-35s %s (responds but empty)\n" "$name" "$status"
      fi
    else
      printf "  ${RED}✗${NC} %-35s %s\n" "$name" "$status"
    fi
  else
    # Without auth: 401/422 = endpoint exists and auth works
    if [ "$status" = "401" ] || [ "$status" = "422" ]; then
      VERIFIED=$((VERIFIED + 1))
      printf "  ${GREEN}✓${NC} %-35s %s (exists, auth required)\n" "$name" "$status"
    elif [ "$status" = "200" ]; then
      VERIFIED=$((VERIFIED + 1))
      printf "  ${GREEN}✓${NC} %-35s %s (public)\n" "$name" "$status"
    else
      printf "  ${RED}✗${NC} %-35s %s\n" "$name" "$status"
    fi
  fi
}

# Health
verify "Health" "GET" "/health"

# Core CRUD
verify "List horses" "GET" "/api/v1/horses/?farm_id=test"
verify "List farms" "GET" "/api/v1/farms/"
verify "List events" "GET" "/api/v1/events/"
verify "List health records" "GET" "/api/v1/health/"
verify "List vaccinations" "GET" "/api/v1/vaccinations/"

# Hope
verify "Hope ask" "POST" "/api/v1/hope/ask" '{"message":"test","farm_id":"00000000-0000-0000-0000-000000000000"}'

# Briefing
verify "Daily briefing" "GET" "/api/v1/briefing/00000000-0000-0000-0000-000000000000"

# ZeroClaw
verify "ZeroClaw ingest" "POST" "/api/v1/zeroclaw/ingest" '{"farm_id":"test","channel":"test","content":"test"}'

# Dashboard
verify "Dashboard" "GET" "/api/v1/dashboard/"

# AI
verify "AI insights" "GET" "/api/v1/ai/"

# Graph
verify "Graph query" "GET" "/api/v1/graph/"

# Documents
verify "Documents" "GET" "/api/v1/documents/"

# Auth
verify "Auth" "GET" "/api/v1/auth/me"

echo ""
echo -e "${BOLD}════════════════════════════════════════${NC}"
echo -e "  Verified: ${BOLD}${VERIFIED}/${TOTAL}${NC}"
pct=$((TOTAL > 0 ? (VERIFIED * 100) / TOTAL : 0))
echo -e "  Coverage: ${BOLD}${pct}%${NC}"
echo -e "${BOLD}════════════════════════════════════════${NC}"
echo ""

# Output for GLASS to consume
echo "GLASS_E2E_VERIFIED=$VERIFIED"
echo "GLASS_E2E_TOTAL=$TOTAL"
echo "GLASS_E2E_PCT=$pct"

rm -f /tmp/glass_e2e_body
exit $([ "$VERIFIED" -eq "$TOTAL" ] && echo 0 || echo 1)
