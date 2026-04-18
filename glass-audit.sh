#!/usr/bin/env bash
# ATLAS v2 — User Story E2E Audit
# NOT siloed. Tests the full flow: frontend → backend → database → response
#
# Usage:
#   bash atlas-audit.sh --frontend PATH --backend PATH --url URL
#
# Runs user stories end-to-end, scores BEFORE and AFTER, generates report.

set -uo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

FRONTEND_PATH=""
BACKEND_PATH=""
LIVE_URL=""
REPORT_FILE="atlas-report-$(date +%Y%m%d-%H%M%S).md"
STORIES=()
INITIAL_SCORES=()
FINAL_SCORES=()
TOTAL_INITIAL=0
TOTAL_FINAL=0
STORY_COUNT=0

while [[ $# -gt 0 ]]; do
  case $1 in
    --frontend) FRONTEND_PATH="$2"; shift 2 ;;
    --backend) BACKEND_PATH="$2"; shift 2 ;;
    --url) LIVE_URL="$2"; shift 2 ;;
    --report) REPORT_FILE="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

# ═══════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════

timestamp() { date -u +%Y-%m-%dT%H:%M:%SZ; }

level_label() {
  case $1 in
    0) echo "DISCUSSED" ;; 1) echo "DESIGNED" ;; 2) echo "CODED" ;;
    3) echo "BUILDS" ;; 4) echo "TESTED" ;; 5) echo "DEPLOYED" ;;
    6) echo "MACHINE-VERIFIED" ;; 7) echo "ACCEPTED" ;; *) echo "UNKNOWN" ;;
  esac
}

gaslight_color() {
  if [ "$1" -ge 5 ]; then echo "$RED"
  elif [ "$1" -ge 3 ]; then echo "$YELLOW"
  else echo "$GREEN"; fi
}

# Record a user story result
# Args: story_name initial_level final_level gaslight detail remedy
record_story() {
  local name="$1" initial="$2" final="$3" gaslight="$4" detail="$5" remedy="${6:-}"
  local color
  color=$(gaslight_color "$gaslight")
  local il fl
  il=$(level_label "$initial")
  fl=$(level_label "$final")

  STORIES+=("$name")
  INITIAL_SCORES+=("$initial")
  FINAL_SCORES+=("$final")
  TOTAL_INITIAL=$((TOTAL_INITIAL + initial))
  TOTAL_FINAL=$((TOTAL_FINAL + final))
  STORY_COUNT=$((STORY_COUNT + 1))

  printf "  %-40s %s→%s  ${color}G:%d${NC}\n" "$name" "$il" "$fl" "$gaslight"
  if [ -n "$detail" ]; then
    echo -e "    ${DIM}$detail${NC}"
  fi
  if [ -n "$remedy" ] && [ "$gaslight" -ge 3 ]; then
    echo -e "    ${CYAN}FIX: $remedy${NC}"
  fi

  # Write to report
  echo "| $name | $il ($initial) | $fl ($final) | $gaslight | $detail | $remedy |" >> "$REPORT_FILE"
}

# ═══════════════════════════════════════════════════
# REPORT HEADER
# ═══════════════════════════════════════════════════

cat > "$REPORT_FILE" << 'HEADER'
# ATLAS Audit Report

| Story | Initial | Final | Gaslight | Detail | Remedy |
|---|---|---|---|---|---|
HEADER

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     ATLAS v2 — User Story E2E Audit                 ║${NC}"
echo -e "${BOLD}║     Not siloed. Full flow: UI → API → DB → Response ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Timestamp: $(timestamp)"
echo "  Frontend:  ${FRONTEND_PATH:-not provided}"
echo "  Backend:   ${BACKEND_PATH:-not provided}"
echo "  Live URL:  ${LIVE_URL:-not provided}"
echo ""

# ═══════════════════════════════════════════════════
# USER STORY 1: "Dean opens the dashboard and sees his horses"
# Full flow: Frontend loads → shows horse list → data source?
# ═══════════════════════════════════════════════════

echo -e "${BOLD}── Story 1: Dean opens dashboard, sees his horses ──${NC}"

fe_data_source="unknown"
fe_gaslight=0
fe_initial=0
fe_final=0
fe_detail=""
fe_remedy=""

if [ -n "$FRONTEND_PATH" ]; then
  # Check: where does the horse list come from?
  api_hook=$(grep -rn "useActiveHorsesApi\|fetchHorses\|/api/v1/horses" \
    "$FRONTEND_PATH/src/" --include="*.tsx" --include="*.ts" 2>/dev/null | \
    grep -v node_modules | grep -v ".test." | head -1)

  mock_import=$(grep -rn "from.*data/mulawa-horses\|from.*data/skyroo-horses" \
    "$FRONTEND_PATH/src/components/" "$FRONTEND_PATH/src/pages/" --include="*.tsx" --include="*.ts" 2>/dev/null | \
    grep -v node_modules | grep -v ".test." | wc -l)
  mock_import=$(echo "$mock_import" | tr -d '[:space:]')

  if [ -n "$api_hook" ]; then
    # Check if the hook actually calls the API or falls back to mock
    hook_file=$(echo "$api_hook" | cut -d: -f1)
    has_fallback=$(grep -c "fallback\|mock\|demo\|hardcoded" "$hook_file" 2>/dev/null || echo 0)
    has_fallback=$(echo "$has_fallback" | tr -d '[:space:]')

    if [ "$has_fallback" -gt 0 ]; then
      fe_data_source="API with mock fallback"
      fe_initial=3
      fe_gaslight=4
      fe_detail="API hook exists but falls back to hardcoded data. $mock_import components import mock data directly."
      fe_remedy="Set VITE_API_URL to backend. Add 'Demo data' banner when using fallback."
    else
      fe_data_source="API"
      fe_initial=4
      fe_gaslight=1
      fe_detail="Fetches from real API"
    fi
  elif [ "$mock_import" -gt 0 ]; then
    fe_data_source="hardcoded mock"
    fe_initial=2
    fe_gaslight=6
    fe_detail="$mock_import components use hardcoded mock data as primary source"
    fe_remedy="Connect to backend API. Add demo banner."
  fi

  # Check: does backend have the endpoint?
  if [ -n "$BACKEND_PATH" ]; then
    has_horses_router=$(grep -c "horses" "$BACKEND_PATH/main.py" 2>/dev/null || echo 0)
    has_horses_router=$(echo "$has_horses_router" | tr -d '[:space:]')
    if [ "$has_horses_router" -gt 0 ]; then
      fe_detail="$fe_detail | Backend router registered."
    fi
  fi

  # Check: does live endpoint respond?
  if [ -n "$LIVE_URL" ]; then
    status=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL/api/v1/horses" 2>/dev/null || echo "000")
    if [ "$status" = "401" ]; then
      fe_detail="$fe_detail | Live endpoint: 401 (exists, needs auth)"
      fe_final=5
    elif [ "$status" = "200" ]; then
      fe_detail="$fe_detail | Live endpoint: 200 OK"
      fe_final=6
    else
      fe_detail="$fe_detail | Live endpoint: $status"
      fe_final=$fe_initial
    fi
  else
    fe_final=$fe_initial
  fi
fi

record_story "Dean sees his horses" "$fe_initial" "$fe_final" "$fe_gaslight" "$fe_detail" "$fe_remedy"
echo ""

# ═══════════════════════════════════════════════════
# USER STORY 2: "Dean asks Hope about a horse"
# Full flow: Chat input → Hope API → agent routing → DB query → response
# ═══════════════════════════════════════════════════

echo -e "${BOLD}── Story 2: Dean asks Hope about a horse ──${NC}"

chat_initial=0
chat_final=0
chat_gaslight=0
chat_detail=""
chat_remedy=""

if [ -n "$FRONTEND_PATH" ]; then
  # Check: does chat call Hope API?
  hope_call=$(grep -rn "hope/ask\|hope.*ask" "$FRONTEND_PATH/src/" --include="*.ts" --include="*.tsx" 2>/dev/null | \
    grep -v node_modules | grep -v ".test." | head -1)

  # Check: does chat still say old name?
  old_name=$(grep -rn "EquestRAI Assistant" "$FRONTEND_PATH/src/components/" --include="*.tsx" 2>/dev/null | \
    grep -v node_modules | grep -v ".test." | wc -l)
  old_name=$(echo "$old_name" | tr -d '[:space:]')

  if [ -n "$hope_call" ]; then
    chat_initial=3
    chat_detail="Chat service calls /api/v1/hope/ask"
  else
    chat_initial=2
    chat_gaslight=5
    chat_detail="Chat does NOT call Hope API"
    chat_remedy="Wire equestrai-chat.ts to POST /api/v1/hope/ask"
  fi

  if [ "$old_name" -gt 0 ]; then
    chat_gaslight=$((chat_gaslight + 3))
    chat_detail="$chat_detail | $old_name files still say 'EquestRAI Assistant'"
    chat_remedy="${chat_remedy} Fix branding in chat component."
  fi
fi

# Check backend
if [ -n "$BACKEND_PATH" ]; then
  hope_router=$(grep -c "hope" "$BACKEND_PATH/main.py" 2>/dev/null || echo 0)
  hope_router=$(echo "$hope_router" | tr -d '[:space:]')
  hope_tests=$(find "$BACKEND_PATH/tests/" -name "*hope*" 2>/dev/null | wc -l)
  hope_tests=$(echo "$hope_tests" | tr -d '[:space:]')

  if [ "$hope_router" -gt 0 ]; then
    chat_detail="$chat_detail | Backend: hope router registered"
  fi
  if [ "$hope_tests" -gt 0 ]; then
    chat_detail="$chat_detail | Tests: exist"
    chat_initial=$((chat_initial > 4 ? chat_initial : 4))
  fi
fi

# Check live
if [ -n "$LIVE_URL" ]; then
  hope_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$LIVE_URL/api/v1/hope/ask" \
    -H "Content-Type: application/json" \
    -d '{"message":"test","farm_id":"00000000-0000-0000-0000-000000000000"}' 2>/dev/null || echo "000")
  if [ "$hope_status" = "401" ]; then
    chat_detail="$chat_detail | Live: 401 (exists)"
    chat_final=5
  elif [ "$hope_status" = "200" ] || [ "$hope_status" = "201" ]; then
    chat_final=6
  else
    chat_detail="$chat_detail | Live: $hope_status"
    chat_final=$chat_initial
  fi
else
  chat_final=$chat_initial
fi

record_story "Dean asks Hope about a horse" "$chat_initial" "$chat_final" "$chat_gaslight" "$chat_detail" "$chat_remedy"
echo ""

# ═══════════════════════════════════════════════════
# USER STORY 3: "Dean takes a photo and it saves"
# Full flow: Camera → capture → upload to Supabase → URL stored
# ═══════════════════════════════════════════════════

echo -e "${BOLD}── Story 3: Dean takes a photo and it persists ──${NC}"

photo_initial=0
photo_final=0
photo_gaslight=0
photo_detail=""
photo_remedy=""

if [ -n "$FRONTEND_PATH" ]; then
  # Check: does PhotoCapture upload to Supabase?
  uploads_to_supabase=$(grep -c "uploadObservationPhoto\|supabase.*storage\|from.*photo-storage" \
    "$FRONTEND_PATH/src/components/PhotoCapture.tsx" 2>/dev/null || echo 0)
  uploads_to_supabase=$(echo "$uploads_to_supabase" | tr -d '[:space:]')

  saves_local_only=$(grep -c "setGallery\|useState.*gallery\|local.*state\|mock.*gallery" \
    "$FRONTEND_PATH/src/components/PhotoCapture.tsx" 2>/dev/null || echo 0)
  saves_local_only=$(echo "$saves_local_only" | tr -d '[:space:]')

  if [ "$uploads_to_supabase" -gt 0 ]; then
    photo_initial=3
    photo_detail="PhotoCapture imports uploadObservationPhoto (Supabase storage)"
    photo_gaslight=2
  else
    photo_initial=2
    photo_detail="PhotoCapture saves to local React state only — ephemeral"
    photo_gaslight=7
    photo_remedy="Import and call uploadObservationPhoto from photo-storage.ts"
  fi

  # Check if horse-media bucket verification exists
  bucket_ref=$(grep -c "horse-media" "$FRONTEND_PATH/src/services/photo-storage.ts" 2>/dev/null || echo 0)
  bucket_ref=$(echo "$bucket_ref" | tr -d '[:space:]')
  if [ "$bucket_ref" -gt 0 ]; then
    photo_detail="$photo_detail | Targets 'horse-media' bucket"
  fi
fi

photo_final=$photo_initial
record_story "Dean takes a photo, it persists" "$photo_initial" "$photo_final" "$photo_gaslight" "$photo_detail" "$photo_remedy"
echo ""

# ═══════════════════════════════════════════════════
# USER STORY 4: "Dean logs a groom observation"
# Full flow: Form → submit → backend API → database
# ═══════════════════════════════════════════════════

echo -e "${BOLD}── Story 4: Dean logs a groom observation ──${NC}"

obs_initial=0
obs_final=0
obs_gaslight=0
obs_detail=""
obs_remedy=""

if [ -n "$FRONTEND_PATH" ]; then
  # Check: does the form submit to API or localStorage?
  form_file="$FRONTEND_PATH/src/components/GroomObservationForm.tsx"
  if [ -f "$form_file" ]; then
    api_submit=$(grep -c "fetch\|api\|useCreate\|mutation\|POST" "$form_file" 2>/dev/null || echo 0)
    api_submit=$(echo "$api_submit" | tr -d '[:space:]')
    local_save=$(grep -c "localStorage\|sessionStorage" "$form_file" 2>/dev/null || echo 0)
    local_save=$(echo "$local_save" | tr -d '[:space:]')

    if [ "$api_submit" -gt 0 ] && [ "$local_save" -eq 0 ]; then
      obs_initial=3
      obs_detail="Form submits via API"
      obs_gaslight=1
    elif [ "$api_submit" -gt 0 ] && [ "$local_save" -gt 0 ]; then
      obs_initial=2
      obs_detail="Has API path but also localStorage fallback"
      obs_gaslight=4
      obs_remedy="Ensure API is primary, localStorage is offline cache only"
    else
      obs_initial=2
      obs_detail="Saves to localStorage only"
      obs_gaslight=6
      obs_remedy="Wire to POST /api/v1/events"
    fi
  else
    obs_initial=0
    obs_detail="GroomObservationForm.tsx not found"
    obs_gaslight=0
  fi
fi

obs_final=$obs_initial
record_story "Dean logs groom observation" "$obs_initial" "$obs_final" "$obs_gaslight" "$obs_detail" "$obs_remedy"
echo ""

# ═══════════════════════════════════════════════════
# USER STORY 5: "Dean gets a morning briefing"
# Full flow: Cron/manual → backend queries → structured summary
# ═══════════════════════════════════════════════════

echo -e "${BOLD}── Story 5: Dean gets morning briefing ──${NC}"

brief_initial=0
brief_final=0
brief_gaslight=0
brief_detail=""
brief_remedy=""

if [ -n "$BACKEND_PATH" ]; then
  if [ -f "$BACKEND_PATH/api/routers/briefing.py" ]; then
    brief_initial=3
    brief_detail="Endpoint exists"

    # Check for N+1
    n1_count=$(grep -c "for h in horses\|for v in vax" "$BACKEND_PATH/api/routers/briefing.py" 2>/dev/null || echo 0)
    n1_count=$(echo "$n1_count" | tr -d '[:space:]')
    if [ "$n1_count" -gt 0 ]; then
      brief_detail="$brief_detail | WARNING: N+1 query pattern ($n1_count loops)"
      brief_gaslight=3
      brief_remedy="Batch query: JOIN horses + vaccinations in single query"
    fi

    # Check for tests
    brief_test=$(find "$BACKEND_PATH/tests/" -name "*briefing*" 2>/dev/null | wc -l)
    brief_test=$(echo "$brief_test" | tr -d '[:space:]')
    if [ "$brief_test" -eq 0 ]; then
      brief_detail="$brief_detail | NO TESTS"
      brief_gaslight=$((brief_gaslight + 2))
      brief_remedy="${brief_remedy} Write tests."
    else
      brief_initial=4
    fi
  fi
fi

if [ -n "$LIVE_URL" ]; then
  bs=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL/api/v1/briefing/00000000-0000-0000-0000-000000000000" 2>/dev/null || echo "000")
  if [ "$bs" = "401" ]; then
    brief_final=5
    brief_detail="$brief_detail | Live: 401 (exists)"
  else
    brief_final=$brief_initial
  fi
else
  brief_final=$brief_initial
fi

record_story "Dean gets morning briefing" "$brief_initial" "$brief_final" "$brief_gaslight" "$brief_detail" "$brief_remedy"
echo ""

# ═══════════════════════════════════════════════════
# USER STORY 6: "Dean clicks a horse → sees full profile"
# Full flow: Click horse → route /horse/:id → profile page renders
# ═══════════════════════════════════════════════════

echo -e "${BOLD}── Story 6: Dean clicks horse → full profile ──${NC}"

prof_initial=0
prof_final=0
prof_gaslight=0
prof_detail=""
prof_remedy=""

if [ -n "$FRONTEND_PATH" ]; then
  # Check route exists
  route_exists=$(grep -c "/horse/:horseId\|/horse/" "$FRONTEND_PATH/src/App.tsx" 2>/dev/null || echo 0)
  route_exists=$(echo "$route_exists" | tr -d '[:space:]')

  # Check profile page exists
  profile_page=$(find "$FRONTEND_PATH/src/" -name "HorseProfilePage*" -o -name "HorseProfileRoute*" 2>/dev/null | wc -l)
  profile_page=$(echo "$profile_page" | tr -d '[:space:]')

  # Check if dashboard horse list links to profile
  horse_click=$(grep -c "onHorseClick\|navigate.*horse\|/horse/" \
    "$FRONTEND_PATH/src/components/FarmDashboard.tsx" "$FRONTEND_PATH/src/components/farm-dashboard/"*.tsx 2>/dev/null || echo 0)
  horse_click=$(echo "$horse_click" | tr -d '[:space:]')

  if [ "$route_exists" -gt 0 ] && [ "$profile_page" -gt 0 ]; then
    prof_initial=3
    prof_detail="Route + page component exist"
    if [ "$horse_click" -gt 0 ]; then
      prof_detail="$prof_detail | Dashboard links to profile"
    else
      prof_detail="$prof_detail | Dashboard does NOT link to profile"
      prof_gaslight=3
      prof_remedy="Add onClick handler to horse list items → navigate(/horse/id)"
    fi
  elif [ "$profile_page" -gt 0 ]; then
    prof_initial=2
    prof_detail="Profile page exists but no route"
    prof_gaslight=4
    prof_remedy="Add Route in App.tsx"
  else
    prof_initial=0
    prof_detail="No horse profile page"
    prof_gaslight=7
    prof_remedy="Create HorseProfilePage component"
  fi
fi

prof_final=$prof_initial
record_story "Dean clicks horse → profile" "$prof_initial" "$prof_final" "$prof_gaslight" "$prof_detail" "$prof_remedy"
echo ""

# ═══════════════════════════════════════════════════
# USER STORY 7: "WhatsApp message → Hope processes it"
# Full flow: ZeroClaw → ingest API → extraction → event
# ═══════════════════════════════════════════════════

echo -e "${BOLD}── Story 7: WhatsApp message → Hope processes ──${NC}"

zc_initial=0
zc_final=0
zc_gaslight=0
zc_detail=""
zc_remedy=""

if [ -n "$BACKEND_PATH" ]; then
  # Ingest endpoint
  ingest=$(grep -c "def ingest_message\|/ingest" "$BACKEND_PATH/api/routers/zeroclaw.py" 2>/dev/null || echo 0)
  ingest=$(echo "$ingest" | tr -d '[:space:]')

  # Extractor
  extractor=$([ -f "$BACKEND_PATH/api/zeroclaw/extractor.py" ] && echo 1 || echo 0)

  # Channel adapter
  adapter=$([ -f "$BACKEND_PATH/api/agents/channel/adapter.py" ] && echo 1 || echo 0)

  if [ "$ingest" -gt 0 ] && [ "$extractor" -eq 1 ]; then
    zc_initial=3
    zc_detail="Ingest endpoint + extractor exist"

    if [ "$adapter" -eq 1 ]; then
      zc_detail="$zc_detail | Channel adapter coded"
    fi

    # But is ZeroClaw actually connected?
    zc_connected=$(docker ps --filter name=zeroclaw 2>/dev/null | grep -c zeroclaw || echo 0)
    if [ "$zc_connected" -gt 0 ]; then
      zc_detail="$zc_detail | ZeroClaw Docker running"
      zc_final=4
    else
      zc_detail="$zc_detail | ZeroClaw NOT running"
      zc_gaslight=5
      zc_remedy="ZeroClaw → Hope bridge not connected. Two separate systems."
      zc_final=$zc_initial
    fi
  fi
fi

if [ -n "$LIVE_URL" ]; then
  zcs=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$LIVE_URL/api/v1/zeroclaw/ingest" \
    -H "Content-Type: application/json" \
    -d '{"farm_id":"00000000-0000-0000-0000-000000000000","channel":"test","content":"test"}' 2>/dev/null || echo "000")
  if [ "$zcs" = "401" ]; then
    zc_detail="$zc_detail | Live ingest: 401 (exists)"
    [ "$zc_final" -lt 5 ] && zc_final=5
  fi
fi

record_story "WhatsApp → Hope processes" "$zc_initial" "$zc_final" "$zc_gaslight" "$zc_detail" "$zc_remedy"
echo ""

# ═══════════════════════════════════════════════════
# USER STORY 8: "Page loads at the top, not partway down"
# ═══════════════════════════════════════════════════

echo -e "${BOLD}── Story 8: Page loads at top ──${NC}"

scroll_initial=0
scroll_final=0
scroll_gaslight=0

if [ -n "$FRONTEND_PATH" ]; then
  has_scroll=$(grep -c "ScrollToTop\|scrollTo(0" "$FRONTEND_PATH/src/App.tsx" 2>/dev/null || echo 0)
  has_scroll=$(echo "$has_scroll" | tr -d '[:space:]')

  if [ "$has_scroll" -gt 0 ]; then
    scroll_initial=3
    scroll_final=5
    scroll_gaslight=0
    record_story "Page loads at top" "$scroll_initial" "$scroll_final" "$scroll_gaslight" "ScrollToTop component in App.tsx" ""
  else
    scroll_initial=0
    scroll_gaslight=4
    record_story "Page loads at top" "$scroll_initial" "$scroll_initial" "$scroll_gaslight" "No ScrollToTop — page may load partway down" "Add ScrollToTop component using useLocation + window.scrollTo(0,0)"
  fi
fi
echo ""

# ═══════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════

echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}FINAL SCORES${NC}"
echo ""

AVG_INITIAL=0
AVG_FINAL=0
if [ "$STORY_COUNT" -gt 0 ]; then
  AVG_INITIAL=$((TOTAL_INITIAL / STORY_COUNT))
  AVG_FINAL=$((TOTAL_FINAL / STORY_COUNT))
fi

echo -e "  Stories tested:      $STORY_COUNT"
echo -e "  Initial avg ATLAS:   ${BOLD}$AVG_INITIAL$(echo "/7 ($(level_label $AVG_INITIAL))")${NC}"
echo -e "  Final avg ATLAS:     ${BOLD}$AVG_FINAL$(echo "/7 ($(level_label $AVG_FINAL))")${NC}"

# Calculate improvement
if [ "$AVG_FINAL" -gt "$AVG_INITIAL" ]; then
  echo -e "  Delta:               ${GREEN}+$((AVG_FINAL - AVG_INITIAL)) levels${NC}"
elif [ "$AVG_FINAL" -lt "$AVG_INITIAL" ]; then
  echo -e "  Delta:               ${RED}$((AVG_FINAL - AVG_INITIAL)) levels (REGRESSED)${NC}"
else
  echo -e "  Delta:               0 (no change)"
fi

echo ""

# Count issues
issue_count=0
for i in "${!STORIES[@]}"; do
  init="${INITIAL_SCORES[$i]}"
  fin="${FINAL_SCORES[$i]}"
  if [ "$fin" -lt 5 ]; then
    issue_count=$((issue_count + 1))
  fi
done

if [ "$issue_count" -eq 0 ]; then
  echo -e "  Verdict: ${GREEN}${BOLD}ALL STORIES VERIFIED${NC}"
elif [ "$issue_count" -le 2 ]; then
  echo -e "  Verdict: ${YELLOW}${BOLD}MOSTLY WORKING${NC} — $issue_count stories below DEPLOYED"
else
  echo -e "  Verdict: ${RED}${BOLD}NOT READY${NC} — $issue_count stories below DEPLOYED"
fi

echo ""

# Append summary to report
cat >> "$REPORT_FILE" << EOF

## Summary

- Stories: $STORY_COUNT
- Initial: $AVG_INITIAL/7
- Final: $AVG_FINAL/7
- Timestamp: $(timestamp)
EOF

echo -e "  Report: ${CYAN}$REPORT_FILE${NC}"
echo ""

# Exit 1 if any story below level 5
if [ "$issue_count" -gt 0 ]; then
  exit 1
fi
exit 0
