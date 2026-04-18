#!/usr/bin/env bash
# ATLAS Self-Audit — runs automatically to catch gaslighting
# Usage: bash atlas-audit.sh [--frontend PATH] [--backend PATH] [--url URL]
#
# Checks:
# 1. Deployed endpoints (200 vs error)
# 2. Mock data detection (hardcoded arrays used as data sources)
# 3. Branding consistency (old names still in code)
# 4. Dead imports / unused components
# 5. Test coverage gaps
# 6. E2E smoke test against live URL
#
# Output: ATLAS level + gaslighting score per feature
# Exit code: 0 if all clean, 1 if gaslighting detected

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

FRONTEND_PATH=""
BACKEND_PATH=""
LIVE_URL=""
GASLIGHT_TOTAL=0
GASLIGHT_COUNT=0
ISSUES=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --frontend) FRONTEND_PATH="$2"; shift 2 ;;
    --backend) BACKEND_PATH="$2"; shift 2 ;;
    --url) LIVE_URL="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║       ATLAS Self-Audit — Gaslight Detector   ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

score_feature() {
  local name="$1"
  local level="$2"
  local gaslight="$3"
  local detail="$4"

  GASLIGHT_TOTAL=$((GASLIGHT_TOTAL + gaslight))
  GASLIGHT_COUNT=$((GASLIGHT_COUNT + 1))

  local color=$GREEN
  if [ "$gaslight" -ge 5 ]; then color=$RED
  elif [ "$gaslight" -ge 3 ]; then color=$YELLOW
  fi

  local level_label="UNKNOWN"
  case $level in
    0) level_label="DISCUSSED" ;;
    1) level_label="DESIGNED" ;;
    2) level_label="CODED" ;;
    3) level_label="BUILDS" ;;
    4) level_label="TESTED" ;;
    5) level_label="DEPLOYED" ;;
    6) level_label="MACHINE-VERIFIED" ;;
    7) level_label="ACCEPTED" ;;
  esac

  printf "  %-35s ATLAS:%-15s ${color}Gaslight: %d/10${NC}\n" "$name" "$level_label" "$gaslight"
  if [ -n "$detail" ]; then
    echo -e "    ${CYAN}→ $detail${NC}"
  fi

  if [ "$gaslight" -ge 4 ]; then
    ISSUES+=("$name (gaslight: $gaslight) — $detail")
  fi
}

# ═══════════════════════════════════════════════════
# CHECK 1: Mock Data Detection
# ═══════════════════════════════════════════════════

if [ -n "$FRONTEND_PATH" ] && [ -d "$FRONTEND_PATH" ]; then
  echo -e "${BOLD}── Mock Data Detection ──${NC}"

  # Find hardcoded data arrays used as primary data sources
  MOCK_FILES=$(grep -rl "mock\|Mock\|MOCK\|hardcoded\|placeholder\|fake\|demo.*data\|sample.*data" \
    "$FRONTEND_PATH/src/data/" 2>/dev/null | wc -l || echo 0)

  # Check if these mock files are imported by actual components (not just tests)
  MOCK_IMPORTS=0
  if [ -d "$FRONTEND_PATH/src/data" ]; then
    for mock_file in "$FRONTEND_PATH/src/data/"*.ts; do
      [ -f "$mock_file" ] || continue
      basename=$(basename "$mock_file" .ts)
      imports=$(grep -rl "from.*data/$basename\|from.*data/${basename}" \
        "$FRONTEND_PATH/src/components/" "$FRONTEND_PATH/src/pages/" 2>/dev/null | wc -l || echo 0)
      if [ "$imports" -gt 0 ]; then
        MOCK_IMPORTS=$((MOCK_IMPORTS + imports))
        score_feature "Mock data: $basename" 2 5 "$imports components import hardcoded data"
      fi
    done
  fi

  if [ "$MOCK_IMPORTS" -eq 0 ]; then
    score_feature "Mock data usage" 4 0 "No mock data imports in components"
  fi
  echo ""
fi

# ═══════════════════════════════════════════════════
# CHECK 2: Branding Consistency
# ═══════════════════════════════════════════════════

if [ -n "$FRONTEND_PATH" ] && [ -d "$FRONTEND_PATH" ]; then
  echo -e "${BOLD}── Branding Consistency ──${NC}"

  # Define what the branding SHOULD be and what it SHOULDN'T be
  OLD_BRAND="EquestRAI Assistant"
  NEW_BRAND="Hope"

  old_count=$(grep -r "$OLD_BRAND" "$FRONTEND_PATH/src/" --include="*.tsx" --include="*.ts" 2>/dev/null | \
    grep -v "node_modules" | grep -v ".test." | wc -l || echo 0)

  new_count=$(grep -r "\"$NEW_BRAND\"" "$FRONTEND_PATH/src/" --include="*.tsx" --include="*.ts" 2>/dev/null | \
    grep -v "node_modules" | grep -v ".test." | wc -l || echo 0)

  if [ "$old_count" -gt 0 ]; then
    score_feature "Branding: old name in code" 2 6 "$old_count files still say '$OLD_BRAND'"
    # Show where
    grep -rn "$OLD_BRAND" "$FRONTEND_PATH/src/" --include="*.tsx" --include="*.ts" 2>/dev/null | \
      grep -v "node_modules" | grep -v ".test." | while read -r line; do
      echo -e "    ${RED}! $line${NC}"
    done
  else
    score_feature "Branding consistency" 5 0 "All references use '$NEW_BRAND'"
  fi
  echo ""
fi

# ═══════════════════════════════════════════════════
# CHECK 3: localStorage as Database (Anti-Pattern)
# ═══════════════════════════════════════════════════

if [ -n "$FRONTEND_PATH" ] && [ -d "$FRONTEND_PATH" ]; then
  echo -e "${BOLD}── localStorage as Database ──${NC}"

  storage_saves=$(grep -rn "localStorage.setItem\|sessionStorage.setItem" \
    "$FRONTEND_PATH/src/" --include="*.tsx" --include="*.ts" 2>/dev/null | \
    grep -v "node_modules" | grep -v ".test." | grep -v "theme\|token\|auth\|preference\|setting" | wc -l || echo 0)

  if [ "$storage_saves" -gt 0 ]; then
    score_feature "localStorage as DB" 2 5 "$storage_saves saves that should go to backend"
    grep -rn "localStorage.setItem" "$FRONTEND_PATH/src/" --include="*.tsx" --include="*.ts" 2>/dev/null | \
      grep -v "node_modules" | grep -v ".test." | grep -v "theme\|token\|auth\|preference\|setting" | \
      head -5 | while read -r line; do
      echo -e "    ${YELLOW}! $line${NC}"
    done
  else
    score_feature "Data persistence" 4 0 "No localStorage abuse detected"
  fi
  echo ""
fi

# ═══════════════════════════════════════════════════
# CHECK 4: Test Coverage Gaps (Backend)
# ═══════════════════════════════════════════════════

if [ -n "$BACKEND_PATH" ] && [ -d "$BACKEND_PATH" ]; then
  echo -e "${BOLD}── Backend Test Coverage ──${NC}"

  for router_file in "$BACKEND_PATH/api/routers/"*.py; do
    [ -f "$router_file" ] || continue
    basename=$(basename "$router_file" .py)
    [ "$basename" = "__init__" ] && continue

    # Check if there's a corresponding test
    has_test=false
    for test_file in "$BACKEND_PATH/tests/"*; do
      if grep -ql "from api.routers.$basename\|routers/$basename\|/$basename" "$test_file" 2>/dev/null; then
        has_test=true
        break
      fi
    done

    if $has_test; then
      score_feature "Backend: $basename" 4 0 "Has test coverage"
    else
      score_feature "Backend: $basename" 3 2 "NO TEST FILE — builds but untested"
    fi
  done
  echo ""
fi

# ═══════════════════════════════════════════════════
# CHECK 5: Deployed Endpoint Smoke Test
# ═══════════════════════════════════════════════════

if [ -n "$LIVE_URL" ]; then
  echo -e "${BOLD}── Live Endpoint Smoke Test ──${NC}"

  # Health check
  health_status=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL/health" 2>/dev/null || echo "000")
  if [ "$health_status" = "200" ]; then
    score_feature "Health endpoint" 6 0 "Returns 200"
  else
    score_feature "Health endpoint" 5 3 "Returns $health_status"
  fi

  # Root
  root_status=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL/" 2>/dev/null || echo "000")
  if [ "$root_status" = "200" ]; then
    score_feature "Root endpoint" 6 0 "Returns 200"
  else
    score_feature "Root endpoint" 5 3 "Returns $root_status"
  fi

  # OpenAPI docs
  docs_status=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL/docs" 2>/dev/null || echo "000")
  if [ "$docs_status" = "200" ]; then
    score_feature "API docs" 6 0 "Swagger UI accessible"
  else
    score_feature "API docs" 5 2 "Returns $docs_status"
  fi

  # Hope endpoint (should 401 without auth, not 404)
  hope_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$LIVE_URL/api/v1/hope/ask" \
    -H "Content-Type: application/json" \
    -d '{"message":"test","farm_id":"00000000-0000-0000-0000-000000000000"}' 2>/dev/null || echo "000")
  if [ "$hope_status" = "401" ]; then
    score_feature "Hope API" 5 0 "Returns 401 (auth required — endpoint exists)"
  elif [ "$hope_status" = "404" ]; then
    score_feature "Hope API" 2 7 "Returns 404 — ENDPOINT NOT DEPLOYED"
  else
    score_feature "Hope API" 5 1 "Returns $hope_status"
  fi

  # Briefing endpoint
  briefing_status=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL/api/v1/briefing/00000000-0000-0000-0000-000000000000" 2>/dev/null || echo "000")
  if [ "$briefing_status" = "401" ]; then
    score_feature "Briefing API" 5 0 "Returns 401 (auth required — endpoint exists)"
  elif [ "$briefing_status" = "404" ]; then
    score_feature "Briefing API" 2 7 "Returns 404 — ENDPOINT NOT DEPLOYED"
  else
    score_feature "Briefing API" 5 1 "Returns $briefing_status"
  fi

  echo ""
fi

# ═══════════════════════════════════════════════════
# CHECK 6: No-Op / Stub Detection
# ═══════════════════════════════════════════════════

if [ -n "$FRONTEND_PATH" ] && [ -d "$FRONTEND_PATH" ]; then
  echo -e "${BOLD}── No-Op / Stub Detection ──${NC}"

  noop_count=$(grep -rn "no-op\|noop\|stub\|TODO\|FIXME\|HACK\|placeholder" \
    "$FRONTEND_PATH/src/" --include="*.tsx" --include="*.ts" 2>/dev/null | \
    grep -v "node_modules" | grep -v ".test." | wc -l || echo 0)

  if [ "$noop_count" -gt 0 ]; then
    score_feature "Stubs/no-ops in code" 2 3 "$noop_count no-op/stub/TODO markers found"
    grep -rn "no-op\|No-op\|noop\|// stub\|// TODO\|// HACK" \
      "$FRONTEND_PATH/src/" --include="*.tsx" --include="*.ts" 2>/dev/null | \
      grep -v "node_modules" | grep -v ".test." | head -5 | while read -r line; do
      echo -e "    ${YELLOW}! $line${NC}"
    done
  else
    score_feature "Code cleanliness" 4 0 "No stubs or no-ops"
  fi
  echo ""
fi

# ═══════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════

echo -e "${BOLD}══════════════════════════════════════════════${NC}"
echo -e "${BOLD}SUMMARY${NC}"
echo ""

if [ "$GASLIGHT_COUNT" -gt 0 ]; then
  AVG=$((GASLIGHT_TOTAL / GASLIGHT_COUNT))
  echo -e "  Features audited:    $GASLIGHT_COUNT"
  echo -e "  Average gaslight:    ${BOLD}$AVG/10${NC}"

  if [ "$AVG" -le 1 ]; then
    echo -e "  Verdict:             ${GREEN}${BOLD}HONEST${NC} — ship it"
  elif [ "$AVG" -le 3 ]; then
    echo -e "  Verdict:             ${YELLOW}${BOLD}MOSTLY HONEST${NC} — fix flagged items"
  elif [ "$AVG" -le 5 ]; then
    echo -e "  Verdict:             ${YELLOW}${BOLD}OVERSOLD${NC} — significant gaps between claims and reality"
  else
    echo -e "  Verdict:             ${RED}${BOLD}GASLIGHTING${NC} — do not ship without fixing"
  fi
else
  echo "  No features audited. Provide --frontend, --backend, or --url paths."
fi

echo ""

if [ ${#ISSUES[@]} -gt 0 ]; then
  echo -e "${RED}${BOLD}ISSUES TO FIX (gaslight >= 4):${NC}"
  for issue in "${ISSUES[@]}"; do
    echo -e "  ${RED}✗${NC} $issue"
  done
  echo ""
  echo -e "${BOLD}SUGGESTED REMEDIES:${NC}"
  for issue in "${ISSUES[@]}"; do
    name=$(echo "$issue" | cut -d'(' -f1 | xargs)
    if echo "$issue" | grep -qi "mock\|hardcoded"; then
      echo -e "  → ${CYAN}$name:${NC} Add 'Demo data' banner OR connect to real API"
    elif echo "$issue" | grep -qi "brand\|name"; then
      echo -e "  → ${CYAN}$name:${NC} Search-replace old branding, verify in browser"
    elif echo "$issue" | grep -qi "localStorage\|storage"; then
      echo -e "  → ${CYAN}$name:${NC} Wire form submissions to backend API endpoints"
    elif echo "$issue" | grep -qi "404\|not deployed"; then
      echo -e "  → ${CYAN}$name:${NC} Check main.py router registration, redeploy"
    elif echo "$issue" | grep -qi "no test\|untested"; then
      echo -e "  → ${CYAN}$name:${NC} Write test, run pytest, verify"
    else
      echo -e "  → ${CYAN}$name:${NC} Investigate and fix"
    fi
  done
fi

echo ""
echo "Audit complete: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# Exit 1 if any gaslight >= 4
if [ ${#ISSUES[@]} -gt 0 ]; then
  exit 1
fi
exit 0
