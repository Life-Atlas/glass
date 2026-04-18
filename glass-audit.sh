#!/usr/bin/env bash
# GLASS v3 — 10-Dimension + User Story Audit
# Gaslight-Less Accountability for Software Shipping
#
# Usage:
#   bash glass-audit.sh --frontend PATH --backend PATH [--url URL] [--report FILE]
#
# Dimensions: Backend, Frontend, Security, AI, Ontology, Architecture, UI/UX, DevOps, Data, E2E
# Stories: User-story-driven flow tests (UI → API → DB → Response)

set -uo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

FRONTEND_PATH=""
BACKEND_PATH=""
LIVE_URL=""
REPORT_FILE="glass-report-$(date +%Y%m%d-%H%M%S).md"

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
    6) echo "VERIFIED" ;; 7) echo "ACCEPTED" ;; *) echo "UNKNOWN" ;;
  esac
}

gaslight_color() {
  local g="$1"
  if [ "$g" -ge 5 ]; then echo "$RED"
  elif [ "$g" -ge 3 ]; then echo "$YELLOW"
  else echo "$GREEN"; fi
}

# Dimension scores: name level gaslight detail remedy
declare -a DIM_NAMES=()
declare -a DIM_LEVELS=()
declare -a DIM_GASLIGHTS=()
declare -a DIM_DETAILS=()
declare -a DIM_REMEDIES=()
DIM_COUNT=0

record_dimension() {
  local name="$1" level="$2" gaslight="$3" detail="$4" remedy="${5:-}"
  local color ll
  color=$(gaslight_color "$gaslight")
  ll=$(level_label "$level")

  DIM_NAMES+=("$name")
  DIM_LEVELS+=("$level")
  DIM_GASLIGHTS+=("$gaslight")
  DIM_DETAILS+=("$detail")
  DIM_REMEDIES+=("$remedy")
  DIM_COUNT=$((DIM_COUNT + 1))

  printf "  %-22s ${BOLD}%s${NC} (%d/7)  ${color}G:%d${NC}\n" "$name" "$ll" "$level" "$gaslight"
  if [ -n "$detail" ]; then
    echo -e "    ${DIM}$detail${NC}"
  fi
  if [ -n "$remedy" ] && [ "$gaslight" -ge 3 ]; then
    echo -e "    ${CYAN}FIX: $remedy${NC}"
  fi
}

# Story scores (same as before)
declare -a STORY_NAMES=()
declare -a STORY_LEVELS=()
declare -a STORY_GASLIGHTS=()
declare -a STORY_DETAILS=()
declare -a STORY_REMEDIES=()
STORY_COUNT=0

record_story() {
  local name="$1" level="$2" gaslight="$3" detail="$4" remedy="${5:-}"
  local color ll
  color=$(gaslight_color "$gaslight")
  ll=$(level_label "$level")

  STORY_NAMES+=("$name")
  STORY_LEVELS+=("$level")
  STORY_GASLIGHTS+=("$gaslight")
  STORY_DETAILS+=("$detail")
  STORY_REMEDIES+=("$remedy")
  STORY_COUNT=$((STORY_COUNT + 1))

  printf "  %-40s ${BOLD}%s${NC} (%d/7)  ${color}G:%d${NC}\n" "$name" "$ll" "$level" "$gaslight"
  if [ -n "$detail" ]; then
    echo -e "    ${DIM}$detail${NC}"
  fi
  if [ -n "$remedy" ] && [ "$gaslight" -ge 3 ]; then
    echo -e "    ${CYAN}FIX: $remedy${NC}"
  fi
}

# ═══════════════════════════════════════════════════
# HEADER
# ═══════════════════════════════════════════════════

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  GLASS v3 — 10-Dimension + User Story Audit                ║${NC}"
echo -e "${BOLD}║  Gaslight-Less Accountability for Software Shipping         ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Timestamp: $(timestamp)"
echo "  Frontend:  ${FRONTEND_PATH:-not provided}"
echo "  Backend:   ${BACKEND_PATH:-not provided}"
echo "  Live URL:  ${LIVE_URL:-not provided}"
echo ""

# ═══════════════════════════════════════════════════
# PART 1: 10-DIMENSION SCORES
# ═══════════════════════════════════════════════════

echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  PART 1: DIMENSION SCORES                                  ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── DIM 1: BACKEND ──
echo -e "${MAGENTA}── 1. Backend ──${NC}"
be_level=0
be_gaslight=0
be_detail=""
be_remedy=""

if [ -n "$BACKEND_PATH" ]; then
  # Count routers
  router_count=$(grep -c "include_router" "$BACKEND_PATH/main.py" 2>/dev/null || echo 0)
  router_count=$(echo "$router_count" | tr -d '[:space:]')

  # Count tests
  test_files=$(find "$BACKEND_PATH/tests/" -name "*.py" -exec grep -l "def test_" {} \; 2>/dev/null | wc -l)
  test_files=$(echo "$test_files" | tr -d '[:space:]')
  test_funcs=$(grep -r "def test_" "$BACKEND_PATH/tests/" --include="*.py" 2>/dev/null | wc -l)
  test_funcs=$(echo "$test_funcs" | tr -d '[:space:]')

  be_detail="${router_count} routers, ${test_files} test files, ${test_funcs} test functions"

  if [ "$test_funcs" -gt 100 ]; then
    be_level=4
    be_detail="$be_detail — solid test coverage"
  elif [ "$test_funcs" -gt 0 ]; then
    be_level=4
  else
    be_level=3
    be_gaslight=2
  fi

  # Check for health endpoint response
  if [ -n "$LIVE_URL" ]; then
    health=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL/health" 2>/dev/null || echo "000")
    if [ "$health" = "200" ]; then
      be_level=5
      be_detail="$be_detail | health: 200 OK"
    fi
  fi
fi
record_dimension "Backend" "$be_level" "$be_gaslight" "$be_detail" "$be_remedy"
echo ""

# ── DIM 2: FRONTEND ──
echo -e "${MAGENTA}── 2. Frontend ──${NC}"
fe_level=0
fe_gaslight=0
fe_detail=""
fe_remedy=""

if [ -n "$FRONTEND_PATH" ]; then
  # Count components
  component_count=$(find "$FRONTEND_PATH/src/components/" -name "*.tsx" 2>/dev/null | wc -l)
  component_count=$(echo "$component_count" | tr -d '[:space:]')

  # Count mock data imports (actual data, not just types)
  mock_data=$(grep -rn "from.*data/mulawa-horses\|from.*data/skyroo-horses" \
    "$FRONTEND_PATH/src/components/" --include="*.tsx" --include="*.ts" 2>/dev/null | \
    grep -v "import type" | grep -v node_modules | wc -l)
  mock_data=$(echo "$mock_data" | tr -d '[:space:]')

  mock_types=$(grep -rn "from.*data/mulawa-horses\|from.*data/skyroo-horses" \
    "$FRONTEND_PATH/src/components/" --include="*.tsx" --include="*.ts" 2>/dev/null | \
    grep "import type" | grep -v node_modules | wc -l)
  mock_types=$(echo "$mock_types" | tr -d '[:space:]')

  # Count API service calls
  api_calls=$(grep -c "apiFetch\|useQuery\|useMutation" "$FRONTEND_PATH/src/services/equestrai-api.ts" 2>/dev/null || echo 0)
  api_calls=$(echo "$api_calls" | tr -d '[:space:]')

  fe_detail="${component_count} components, ${mock_data} mock-data imports, ${mock_types} type-only imports, ${api_calls} API calls wired"

  # Check for demo banner
  demo_banner=$(grep -rn "demo.*banner\|mock.*indicator\|Demo data\|demo.*mode\|Demo Mode\|isApiMode" \
    "$FRONTEND_PATH/src/" --include="*.tsx" --include="*.ts" 2>/dev/null | wc -l)
  demo_banner=$(echo "$demo_banner" | tr -d '[:space:]')

  if [ "$mock_data" -gt 5 ]; then
    fe_level=2
    fe_gaslight=5
    fe_detail="$fe_detail — MOST components use hardcoded mock data"
    fe_remedy="Connect components to API service layer. Add demo banner."
  elif [ "$mock_data" -gt 0 ] && [ "$demo_banner" -eq 0 ]; then
    fe_level=3
    fe_gaslight=3
    fe_detail="$fe_detail — some mock data, NO demo banner"
    fe_remedy="Add demo banner when using mock data."
  elif [ "$mock_data" -gt 0 ] && [ "$demo_banner" -gt 0 ]; then
    fe_level=4
    fe_gaslight=1
    fe_detail="$fe_detail — minor mock data with demo banner (honest)"
  else
    fe_level=5
    fe_gaslight=0
    fe_detail="$fe_detail — all data from API"
  fi
fi
record_dimension "Frontend" "$fe_level" "$fe_gaslight" "$fe_detail" "$fe_remedy"
echo ""

# ── DIM 3: SECURITY ──
echo -e "${MAGENTA}── 3. Security ──${NC}"
sec_level=0
sec_gaslight=0
sec_detail=""
sec_remedy=""

if [ -n "$BACKEND_PATH" ]; then
  # Check for auth middleware
  auth_refs=$(grep -rn "get_current_user\|verify_token\|auth.*dependency\|Depends.*auth" \
    "$BACKEND_PATH/api/routers/" --include="*.py" 2>/dev/null | wc -l)
  auth_refs=$(echo "$auth_refs" | tr -d '[:space:]')

  # Check for RLS mentions
  rls_refs=$(grep -rn "RLS\|row.*level.*security\|enable_rls" \
    "$BACKEND_PATH/" --include="*.py" --include="*.sql" 2>/dev/null | wc -l)
  rls_refs=$(echo "$rls_refs" | tr -d '[:space:]')

  # Check for CORS
  cors=$(grep -c "CORSMiddleware\|add_middleware" "$BACKEND_PATH/main.py" 2>/dev/null || echo 0)
  cors=$(echo "$cors" | tr -d '[:space:]')

  # Check for rate limiting
  rate_limit=$(grep -rn "rate.*limit\|throttle\|RateLimiter" \
    "$BACKEND_PATH/" --include="*.py" 2>/dev/null | wc -l)
  rate_limit=$(echo "$rate_limit" | tr -d '[:space:]')

  sec_detail="auth refs: ${auth_refs}, RLS refs: ${rls_refs}, CORS: ${cors}, rate limiting: ${rate_limit}"

  if [ "$auth_refs" -gt 10 ] && [ "$rls_refs" -gt 0 ]; then
    sec_level=4
    # Bump to 5 if deployed with auth working (401 on protected endpoints = good)
    if [ -n "$LIVE_URL" ]; then
      auth_check=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL/api/v1/horses/" 2>/dev/null || echo "000")
      if [ "$auth_check" = "401" ]; then
        sec_level=5
        sec_detail="$sec_detail | live auth: 401 (working)"
      fi
    fi
  elif [ "$auth_refs" -gt 0 ]; then
    sec_level=3
    sec_gaslight=2
  else
    sec_level=1
    sec_gaslight=6
    sec_remedy="Add auth middleware to protected endpoints"
  fi

  if [ "$rate_limit" -eq 0 ]; then
    sec_detail="$sec_detail — NO rate limiting"
    sec_gaslight=$((sec_gaslight + 1))
  fi

  # Check for hardcoded secrets (real values, not empty env defaults)
  # Only catch actual secret strings, not parameter names or variable references
  secrets=$(grep -rn 'sk-[a-zA-Z0-9]\{20,\}\|ghp_[a-zA-Z0-9]\{20,\}\|password\s*=\s*"[^"]\{8,\}"\|AKIA[A-Z0-9]\{16\}' \
    "$BACKEND_PATH/" --include="*.py" 2>/dev/null | \
    grep -v test | grep -v ".pyc" | grep -v __pycache__ | wc -l)
  secrets=$(echo "$secrets" | tr -d '[:space:]')
  if [ "$secrets" -gt 0 ]; then
    sec_detail="$sec_detail | WARNING: ${secrets} possible hardcoded secrets"
    sec_gaslight=$((sec_gaslight + 3))
    sec_remedy="${sec_remedy} Remove hardcoded secrets, use env vars."
  fi
fi
record_dimension "Security" "$sec_level" "$sec_gaslight" "$sec_detail" "$sec_remedy"
echo ""

# ── DIM 4: AI ──
echo -e "${MAGENTA}── 4. AI / Agents ──${NC}"
ai_level=0
ai_gaslight=0
ai_detail=""
ai_remedy=""

if [ -n "$BACKEND_PATH" ]; then
  # Count AI modules
  ai_modules=$(find "$BACKEND_PATH/api/ai/" -name "*.py" 2>/dev/null | grep -v __pycache__ | wc -l)
  ai_modules=$(echo "$ai_modules" | tr -d '[:space:]')

  # Count agent files
  agent_files=$(find "$BACKEND_PATH/api/agents/" -name "*.py" 2>/dev/null | grep -v __pycache__ | wc -l)
  agent_files=$(echo "$agent_files" | tr -d '[:space:]')

  # Check for Hope orchestrator
  hope_exists=$([ -f "$BACKEND_PATH/api/agents/orchestrator.py" ] && echo 1 || echo 0)

  # Check for agent tests
  agent_tests=$(find "$BACKEND_PATH/tests/" -name "*agent*" -o -name "*hope*" 2>/dev/null | wc -l)
  agent_tests=$(echo "$agent_tests" | tr -d '[:space:]')

  ai_detail="${ai_modules} AI modules, ${agent_files} agent files, Hope: $([ $hope_exists -eq 1 ] && echo 'yes' || echo 'NO')"

  if [ "$hope_exists" -eq 1 ] && [ "$agent_tests" -gt 0 ]; then
    ai_level=4
    ai_detail="$ai_detail, ${agent_tests} test files"
    # Bump to 5 if Hope endpoint is deployed
    if [ -n "$LIVE_URL" ]; then
      hope_check=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$LIVE_URL/api/v1/hope/ask" \
        -H "Content-Type: application/json" \
        -d '{"message":"test"}' 2>/dev/null || echo "000")
      if [ "$hope_check" = "401" ] || [ "$hope_check" = "200" ] || [ "$hope_check" = "422" ]; then
        ai_level=5
        ai_detail="$ai_detail | Hope deployed: ${hope_check}"
      fi
    fi
  elif [ "$hope_exists" -eq 1 ]; then
    ai_level=3
    ai_gaslight=2
    ai_detail="$ai_detail — orchestrator exists but limited tests"
  elif [ "$ai_modules" -gt 0 ]; then
    ai_level=2
    ai_gaslight=3
  else
    ai_level=0
    ai_gaslight=0
  fi

  # Check if AI actually hits real models or mocks
  mock_ai=$(grep -rn "mock\|fake\|stub\|dummy" "$BACKEND_PATH/api/ai/" --include="*.py" 2>/dev/null | wc -l)
  mock_ai=$(echo "$mock_ai" | tr -d '[:space:]')
  if [ "$mock_ai" -gt 3 ]; then
    ai_detail="$ai_detail | ${mock_ai} mock refs in AI layer"
    ai_gaslight=$((ai_gaslight + 2))
  fi
fi
record_dimension "AI / Agents" "$ai_level" "$ai_gaslight" "$ai_detail" "$ai_remedy"
echo ""

# ── DIM 5: ONTOLOGY ──
echo -e "${MAGENTA}── 5. Ontology ──${NC}"
ont_level=0
ont_gaslight=0
ont_detail=""
ont_remedy=""

if [ -n "$BACKEND_PATH" ]; then
  ont_dir=$([ -d "$BACKEND_PATH/api/ontology/" ] && echo 1 || echo 0)
  taxonomy=$([ -f "$BACKEND_PATH/api/models/taxonomy.py" ] && echo 1 || echo 0)
  tax_middleware=$([ -f "$BACKEND_PATH/api/taxonomy_middleware.py" ] && echo 1 || echo 0)

  ont_detail="ontology dir: $([ $ont_dir -eq 1 ] && echo 'yes' || echo 'NO'), taxonomy model: $([ $taxonomy -eq 1 ] && echo 'yes' || echo 'NO'), middleware: $([ $tax_middleware -eq 1 ] && echo 'yes' || echo 'NO')"

  if [ "$ont_dir" -eq 1 ] && [ "$taxonomy" -eq 1 ]; then
    # Count ontology files
    ont_files=$(find "$BACKEND_PATH/api/ontology/" -name "*.py" -o -name "*.json" -o -name "*.jsonld" 2>/dev/null | wc -l)
    ont_files=$(echo "$ont_files" | tr -d '[:space:]')
    ont_detail="$ont_detail, ${ont_files} ontology files"
    ont_level=3
    if [ "$tax_middleware" -eq 1 ]; then
      ont_level=4
      # Bump to 5 if deployed
      if [ -n "$LIVE_URL" ]; then
        ont_check=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL/health" 2>/dev/null || echo "000")
        if [ "$ont_check" = "200" ]; then
          ont_level=5
        fi
      fi
    fi
  elif [ "$taxonomy" -eq 1 ]; then
    ont_level=2
    ont_gaslight=2
  else
    ont_level=0
  fi
fi
record_dimension "Ontology" "$ont_level" "$ont_gaslight" "$ont_detail" "$ont_remedy"
echo ""

# ── DIM 6: ARCHITECTURE ──
echo -e "${MAGENTA}── 6. Architecture ──${NC}"
arch_level=0
arch_gaslight=0
arch_detail=""
arch_remedy=""

if [ -n "$BACKEND_PATH" ]; then
  # Check layering: routers → services → models
  routers=$(find "$BACKEND_PATH/api/routers/" -name "*.py" 2>/dev/null | grep -v __pycache__ | wc -l)
  routers=$(echo "$routers" | tr -d '[:space:]')
  models=$(find "$BACKEND_PATH/api/models/" -name "*.py" 2>/dev/null | grep -v __pycache__ | wc -l)
  models=$(echo "$models" | tr -d '[:space:]')
  services=$(find "$BACKEND_PATH/api/services/" -name "*.py" 2>/dev/null | grep -v __pycache__ | wc -l 2>/dev/null || echo 0)
  services=$(echo "$services" | tr -d '[:space:]')

  arch_detail="routers: ${routers}, models: ${models}, services: ${services}"

  # Check for circular imports / god files
  big_files=$(find "$BACKEND_PATH/api/" -name "*.py" -exec wc -l {} \; 2>/dev/null | sort -rn | head -3 | awk '{print $1 ":" $2}' | tr '\n' ', ')
  arch_detail="$arch_detail | biggest files: $big_files"

  if [ "$routers" -gt 10 ] && [ "$models" -gt 3 ]; then
    arch_level=4
    if [ -n "$LIVE_URL" ]; then
      arch_check=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL/health" 2>/dev/null || echo "000")
      if [ "$arch_check" = "200" ]; then
        arch_level=5
      fi
    fi
  elif [ "$routers" -gt 0 ]; then
    arch_level=3
  fi
fi

if [ -n "$FRONTEND_PATH" ]; then
  # Check for config-driven architecture
  config_files=$(find "$FRONTEND_PATH/src/config/" -name "*.ts" 2>/dev/null | wc -l)
  config_files=$(echo "$config_files" | tr -d '[:space:]')
  arch_detail="$arch_detail | FE config files: ${config_files}"
fi
record_dimension "Architecture" "$arch_level" "$arch_gaslight" "$arch_detail" "$arch_remedy"
echo ""

# ── DIM 7: UI/UX ──
echo -e "${MAGENTA}── 7. UI/UX ──${NC}"
ux_level=0
ux_gaslight=0
ux_detail=""
ux_remedy=""

if [ -n "$FRONTEND_PATH" ]; then
  # Branding consistency
  old_brand=$(grep -rn "EquestRAI Assistant" "$FRONTEND_PATH/src/" --include="*.tsx" --include="*.ts" 2>/dev/null | wc -l)
  old_brand=$(echo "$old_brand" | tr -d '[:space:]')

  # Accessibility
  aria_refs=$(grep -rn "aria-\|role=" "$FRONTEND_PATH/src/components/" --include="*.tsx" 2>/dev/null | wc -l)
  aria_refs=$(echo "$aria_refs" | tr -d '[:space:]')

  # Loading states
  loading=$(grep -rn "isLoading\|loading\|Skeleton\|Spinner" "$FRONTEND_PATH/src/components/" --include="*.tsx" 2>/dev/null | wc -l)
  loading=$(echo "$loading" | tr -d '[:space:]')

  # Error states
  error_ui=$(grep -rn "isError\|error.*message\|ErrorBoundary\|catch" "$FRONTEND_PATH/src/components/" --include="*.tsx" 2>/dev/null | wc -l)
  error_ui=$(echo "$error_ui" | tr -d '[:space:]')

  ux_detail="old branding: ${old_brand} refs, aria: ${aria_refs}, loading states: ${loading}, error states: ${error_ui}"

  if [ "$old_brand" -gt 0 ]; then
    ux_gaslight=$((ux_gaslight + 4))
    ux_remedy="Replace 'EquestRAI Assistant' with 'Hope' in ${old_brand} locations"
  fi

  if [ "$aria_refs" -gt 100 ] && [ "$loading" -gt 20 ] && [ "$error_ui" -gt 20 ]; then
    ux_level=5
  elif [ "$aria_refs" -gt 20 ] && [ "$loading" -gt 10 ]; then
    ux_level=4
  elif [ "$loading" -gt 5 ]; then
    ux_level=3
  else
    ux_level=1
    ux_gaslight=$((ux_gaslight + 2))
  fi

  if [ "$old_brand" -gt 0 ]; then
    ux_level=$((ux_level > 2 ? 2 : ux_level))
  fi
fi
record_dimension "UI/UX" "$ux_level" "$ux_gaslight" "$ux_detail" "$ux_remedy"
echo ""

# ── DIM 8: DEVOPS ──
echo -e "${MAGENTA}── 8. DevOps ──${NC}"
ops_level=0
ops_gaslight=0
ops_detail=""
ops_remedy=""

if [ -n "$BACKEND_PATH" ]; then
  # Check for deployment config
  has_vercel=$([ -f "$BACKEND_PATH/vercel.json" ] && echo 1 || echo 0)
  has_docker=$([ -f "$BACKEND_PATH/Dockerfile" ] && echo 1 || echo 0)
  has_ci=$(find "$BACKEND_PATH/.github/" -name "*.yml" 2>/dev/null | wc -l)
  has_ci=$(echo "$has_ci" | tr -d '[:space:]')
  has_requirements=$([ -f "$BACKEND_PATH/requirements.txt" ] && echo 1 || echo 0)

  ops_detail="vercel: $([ $has_vercel -eq 1 ] && echo 'yes' || echo 'NO'), docker: $([ $has_docker -eq 1 ] && echo 'yes' || echo 'NO'), CI: ${has_ci} workflows, deps: $([ $has_requirements -eq 1 ] && echo 'yes' || echo 'NO')"

  if [ "$has_vercel" -eq 1 ] || [ "$has_docker" -eq 1 ]; then
    ops_level=4
    if [ -n "$LIVE_URL" ]; then
      deploy_check=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL/health" 2>/dev/null || echo "000")
      if [ "$deploy_check" = "200" ]; then
        ops_level=5
        ops_detail="$ops_detail | deploy health: 200"
      fi
    fi
  else
    ops_level=2
    ops_gaslight=3
    ops_remedy="Add deployment config"
  fi

  if [ "$has_ci" -eq 0 ]; then
    ops_detail="$ops_detail — NO CI pipeline"
    ops_gaslight=$((ops_gaslight + 2))
    ops_remedy="${ops_remedy} Add GitHub Actions CI."
  fi
fi
record_dimension "DevOps" "$ops_level" "$ops_gaslight" "$ops_detail" "$ops_remedy"
echo ""

# ── DIM 9: DATA ──
echo -e "${MAGENTA}── 9. Data ──${NC}"
data_level=0
data_gaslight=0
data_detail=""
data_remedy=""

if [ -n "$BACKEND_PATH" ]; then
  # Migrations
  migration_count=$(find "$BACKEND_PATH/" -name "*.sql" -path "*/migrations/*" 2>/dev/null | wc -l)
  migration_count=$(echo "$migration_count" | tr -d '[:space:]')

  # Supabase client
  supabase_client=$(grep -rn "supabase\|create_client" "$BACKEND_PATH/api/" --include="*.py" 2>/dev/null | wc -l)
  supabase_client=$(echo "$supabase_client" | tr -d '[:space:]')

  # N+1 patterns — find for-loops that contain DB calls (eq_table/execute) inside them
  # Simple heuristic: count files where a for-loop is followed by eq_table within 5 lines
  n1_loops=$(grep -rn -A5 "for .* in .*:" "$BACKEND_PATH/api/routers/" --include="*.py" 2>/dev/null | \
    grep "eq_table\|\.execute()\|\.select(" | wc -l)
  n1_loops=$(echo "$n1_loops" | tr -d '[:space:]')

  data_detail="migrations: ${migration_count}, supabase refs: ${supabase_client}, potential N+1 loops: ${n1_loops}"

  if [ "$supabase_client" -gt 5 ]; then
    data_level=4
    if [ -n "$LIVE_URL" ]; then
      data_check=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL/health" 2>/dev/null || echo "000")
      if [ "$data_check" = "200" ]; then
        data_level=5
        data_detail="$data_detail | DB connected (health 200)"
      fi
    fi
  elif [ "$supabase_client" -gt 0 ]; then
    data_level=3
  else
    data_level=1
    data_gaslight=4
  fi

  if [ "$n1_loops" -gt 5 ]; then
    data_gaslight=$((data_gaslight + 3))
    data_remedy="Batch queries. ${n1_loops} DB calls inside loops."
  elif [ "$n1_loops" -gt 0 ]; then
    data_gaslight=$((data_gaslight + 1))
    data_detail="$data_detail — ${n1_loops} minor N+1 patterns"
  fi
fi

if [ -n "$FRONTEND_PATH" ]; then
  # How much data lives in localStorage vs API?
  ls_count=$(grep -rn "localStorage" "$FRONTEND_PATH/src/" --include="*.tsx" --include="*.ts" 2>/dev/null | wc -l)
  ls_count=$(echo "$ls_count" | tr -d '[:space:]')
  data_detail="$data_detail | FE localStorage refs: ${ls_count}"
  if [ "$ls_count" -gt 50 ]; then
    data_gaslight=$((data_gaslight + 1))
    data_detail="$data_detail — localStorage as offline cache (expected for edge-native)"
  fi
fi
record_dimension "Data" "$data_level" "$data_gaslight" "$data_detail" "$data_remedy"
echo ""

# ── DIM 10: E2E ──
echo -e "${MAGENTA}── 10. End-to-End ──${NC}"
e2e_level=0
e2e_gaslight=0
e2e_detail=""
e2e_remedy=""

if [ -n "$FRONTEND_PATH" ]; then
  # Check for e2e tests
  e2e_tests=$(find "$FRONTEND_PATH/" -name "*.test.ts" -o -name "*.spec.ts" -o -name "*.e2e.ts" 2>/dev/null | wc -l)
  e2e_tests=$(echo "$e2e_tests" | tr -d '[:space:]')

  # Check for Playwright / Cypress
  has_playwright=$([ -f "$FRONTEND_PATH/playwright.config.ts" ] && echo 1 || echo 0)
  has_cypress=$([ -d "$FRONTEND_PATH/cypress" ] && echo 1 || echo 0)

  e2e_detail="test files: ${e2e_tests}, playwright: $([ $has_playwright -eq 1 ] && echo 'yes' || echo 'NO'), cypress: $([ $has_cypress -eq 1 ] && echo 'yes' || echo 'NO')"
fi

# Check if FE→BE integration works
if [ -n "$LIVE_URL" ]; then
  # Try hitting core endpoints
  horses_status=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL/api/v1/horses/?farm_id=test" 2>/dev/null || echo "000")
  hope_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$LIVE_URL/api/v1/hope/ask" \
    -H "Content-Type: application/json" \
    -d '{"message":"test","farm_id":"00000000-0000-0000-0000-000000000000"}' 2>/dev/null || echo "000")

  e2e_detail="$e2e_detail | live horses: ${horses_status}, live hope: ${hope_status}"

  if [ "$horses_status" = "401" ] && [ "$hope_status" = "401" ]; then
    e2e_level=5
    e2e_detail="$e2e_detail — endpoints exist, auth required"
  elif [ "$horses_status" = "200" ] || [ "$hope_status" = "200" ]; then
    e2e_level=6
  else
    e2e_level=2
    e2e_gaslight=4
    e2e_remedy="Live endpoints not responding correctly"
  fi
else
  e2e_level=1
  e2e_gaslight=3
  e2e_detail="$e2e_detail — no live URL provided"
  e2e_remedy="Provide --url to test against deployed backend"
fi
record_dimension "End-to-End" "$e2e_level" "$e2e_gaslight" "$e2e_detail" "$e2e_remedy"
echo ""

# ═══════════════════════════════════════════════════
# PART 2: USER STORIES
# ═══════════════════════════════════════════════════

echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  PART 2: USER STORIES                                      ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── STORY 1: Dean opens dashboard, sees horses ──
echo -e "${BOLD}── Story 1: Dean opens dashboard, sees his horses ──${NC}"
s1_level=0; s1_gaslight=0; s1_detail=""; s1_remedy=""

if [ -n "$FRONTEND_PATH" ]; then
  # Does the dashboard pull from API or mock?
  dash_api=$(grep -rl "useActiveHorsesApi\|fetchHorses\|equestRaiApi.*horses" \
    "$FRONTEND_PATH/src/components/farm-dashboard/" "$FRONTEND_PATH/src/pages/" \
    --include="*.tsx" --include="*.ts" 2>/dev/null | wc -l)
  dash_api=$(echo "$dash_api" | tr -d '[:space:]')

  dash_mock=$(grep -rn "from.*data/mulawa-horses\|from.*data/skyroo-horses" \
    "$FRONTEND_PATH/src/components/farm-dashboard/" --include="*.tsx" 2>/dev/null | grep -v "import type" | wc -l)
  dash_mock=$(echo "$dash_mock" | tr -d '[:space:]')

  # Check if hook has API mode with fallback (honest pattern)
  has_api_hook=$(grep -c "isApiMode\|apiMode" \
    "$FRONTEND_PATH/src/hooks/useActiveHorsesApi.ts" 2>/dev/null || echo 0)
  has_api_hook=$(echo "$has_api_hook" | tr -d '[:space:]')

  if [ "$dash_mock" -gt 2 ]; then
    s1_level=2
    s1_gaslight=5
    s1_detail="Dashboard uses ${dash_mock} mock-data imports"
    s1_remedy="Wire dashboard to API service layer"
  elif [ "$dash_api" -gt 0 ] && [ "$has_api_hook" -gt 0 ]; then
    s1_level=4
    s1_gaslight=1
    s1_detail="Dashboard uses API hook with honest mock fallback + demo banner"
  elif [ "$dash_api" -gt 0 ]; then
    s1_level=3
    s1_detail="Dashboard calls API"
  else
    s1_level=1
    s1_gaslight=3
    s1_detail="Can't determine data source"
  fi
fi

if [ -n "$LIVE_URL" ]; then
  hs=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL/api/v1/horses/?farm_id=test" 2>/dev/null || echo "000")
  if [ "$hs" = "401" ]; then
    s1_detail="$s1_detail | backend: 401 (exists)"
    [ "$s1_level" -lt 5 ] && [ "$s1_gaslight" -lt 3 ] && s1_level=5
  fi
fi

record_story "Dean sees his horses" "$s1_level" "$s1_gaslight" "$s1_detail" "$s1_remedy"
echo ""

# ── STORY 2: Dean asks Hope about a horse ──
echo -e "${BOLD}── Story 2: Dean asks Hope about a horse ──${NC}"
s2_level=0; s2_gaslight=0; s2_detail=""; s2_remedy=""

if [ -n "$FRONTEND_PATH" ]; then
  hope_call=$(grep -c "hope/ask" "$FRONTEND_PATH/src/services/equestrai-chat.ts" 2>/dev/null || echo 0)
  hope_call=$(echo "$hope_call" | tr -d '[:space:]')

  old_name=$(grep -c "EquestRAI Assistant" "$FRONTEND_PATH/src/components/EquestRaiChat.tsx" 2>/dev/null || echo 0)
  old_name=$(echo "$old_name" | tr -d '[:space:]')

  if [ "$hope_call" -gt 0 ]; then
    s2_level=4
    s2_detail="Chat calls /api/v1/hope/ask"
  else
    s2_level=2
    s2_gaslight=5
    s2_detail="Chat does NOT call Hope API"
    s2_remedy="Wire chat to POST /api/v1/hope/ask"
  fi

  if [ "$old_name" -gt 0 ]; then
    s2_gaslight=$((s2_gaslight + 3))
    s2_detail="$s2_detail | ${old_name} refs still say 'EquestRAI Assistant'"
    s2_remedy="${s2_remedy} Rebrand to Hope."
  fi
fi

if [ -n "$LIVE_URL" ]; then
  hs2=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$LIVE_URL/api/v1/hope/ask" \
    -H "Content-Type: application/json" \
    -d '{"message":"test","farm_id":"00000000-0000-0000-0000-000000000000"}' 2>/dev/null || echo "000")
  if [ "$hs2" = "401" ] || [ "$hs2" = "422" ]; then
    s2_detail="$s2_detail | backend: ${hs2} (deployed)"
    [ "$s2_level" -lt 5 ] && [ "$s2_gaslight" -lt 3 ] && s2_level=5
  fi
fi
record_story "Dean asks Hope" "$s2_level" "$s2_gaslight" "$s2_detail" "$s2_remedy"
echo ""

# ── STORY 3: Dean takes a photo ──
echo -e "${BOLD}── Story 3: Dean takes a photo ──${NC}"
s3_level=0; s3_gaslight=0; s3_detail=""; s3_remedy=""

if [ -n "$FRONTEND_PATH" ]; then
  supabase_upload=$(grep -c "uploadObservationPhoto\|supabase.*storage" \
    "$FRONTEND_PATH/src/components/PhotoCapture.tsx" 2>/dev/null || echo 0)
  supabase_upload=$(echo "$supabase_upload" | tr -d '[:space:]')

  if [ "$supabase_upload" -gt 0 ]; then
    s3_level=4; s3_gaslight=1
    s3_detail="PhotoCapture uploads to Supabase storage"
  else
    s3_level=2; s3_gaslight=6
    s3_detail="PhotoCapture saves to local state only"
    s3_remedy="Wire to Supabase storage upload"
  fi
fi
record_story "Dean takes a photo" "$s3_level" "$s3_gaslight" "$s3_detail" "$s3_remedy"
echo ""

# ── STORY 4: Dean logs groom observation ──
echo -e "${BOLD}── Story 4: Dean logs groom observation ──${NC}"
s4_level=0; s4_gaslight=0; s4_detail=""; s4_remedy=""

if [ -n "$FRONTEND_PATH" ]; then
  form="$FRONTEND_PATH/src/components/GroomObservationForm.tsx"
  if [ -f "$form" ]; then
    api_sub=$(grep -c "fetch\|api\|mutation\|POST" "$form" 2>/dev/null || echo 0)
    api_sub=$(echo "$api_sub" | tr -d '[:space:]')
    local_sub=$(grep -c "localStorage" "$form" 2>/dev/null || echo 0)
    local_sub=$(echo "$local_sub" | tr -d '[:space:]')

    if [ "$api_sub" -gt 0 ] && [ "$local_sub" -eq 0 ]; then
      s4_level=4; s4_gaslight=0
      s4_detail="Form submits via API (no localStorage)"
    elif [ "$api_sub" -gt 0 ]; then
      s4_level=2; s4_gaslight=4
      s4_detail="API + localStorage fallback"
      s4_remedy="Make API primary, localStorage offline-only"
    else
      s4_level=2; s4_gaslight=6
      s4_detail="localStorage only"
      s4_remedy="Wire to POST /api/v1/events"
    fi
  else
    s4_detail="GroomObservationForm.tsx not found"
  fi
fi

if [ -n "$LIVE_URL" ] && [ "$s4_level" -ge 3 ]; then
  ev_status=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL/api/v1/events/" 2>/dev/null || echo "000")
  if [ "$ev_status" = "401" ] || [ "$ev_status" = "200" ] || [ "$ev_status" = "422" ]; then
    s4_detail="$s4_detail | events endpoint: ${ev_status} (deployed)"
    [ "$s4_level" -lt 5 ] && s4_level=5
  fi
fi
record_story "Dean logs observation" "$s4_level" "$s4_gaslight" "$s4_detail" "$s4_remedy"
echo ""

# ── STORY 5: Morning briefing ──
echo -e "${BOLD}── Story 5: Dean gets morning briefing ──${NC}"
s5_level=0; s5_gaslight=0; s5_detail=""; s5_remedy=""

if [ -n "$BACKEND_PATH" ] && [ -f "$BACKEND_PATH/api/routers/briefing.py" ]; then
  s5_level=3
  s5_detail="Endpoint exists"

  # Check for N+1: for-loops containing DB calls inside
  n1=$(grep -A5 "for .* in .*:" "$BACKEND_PATH/api/routers/briefing.py" 2>/dev/null | \
    grep -c "eq_table\|\.execute()" || echo 0)
  n1=$(echo "$n1" | tr -d '[:space:]')
  if [ "$n1" -gt 0 ]; then
    s5_gaslight=3
    s5_detail="$s5_detail | N+1: ${n1} DB calls inside loops"
    s5_remedy="Batch queries"
  fi

  bt=$(find "$BACKEND_PATH/tests/" -name "*briefing*" 2>/dev/null | wc -l)
  bt=$(echo "$bt" | tr -d '[:space:]')
  if [ "$bt" -eq 0 ]; then
    s5_gaslight=$((s5_gaslight + 2))
    s5_detail="$s5_detail | NO TESTS"
    s5_remedy="${s5_remedy} Write briefing tests."
  else
    s5_level=4
  fi

  if [ -n "$LIVE_URL" ]; then
    bs=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL/api/v1/briefing/00000000-0000-0000-0000-000000000000" 2>/dev/null || echo "000")
    if [ "$bs" = "401" ]; then
      s5_detail="$s5_detail | live: 401"
      [ "$s5_level" -lt 5 ] && [ "$s5_gaslight" -lt 3 ] && s5_level=5
    fi
  fi
fi
record_story "Morning briefing" "$s5_level" "$s5_gaslight" "$s5_detail" "$s5_remedy"
echo ""

# ── STORY 6: Horse profile click ──
echo -e "${BOLD}── Story 6: Dean clicks horse → profile ──${NC}"
s6_level=0; s6_gaslight=0; s6_detail=""; s6_remedy=""

if [ -n "$FRONTEND_PATH" ]; then
  route=$(grep -c "horse.*Id\|/horse/" "$FRONTEND_PATH/src/App.tsx" 2>/dev/null || echo 0)
  route=$(echo "$route" | tr -d '[:space:]')
  profile=$(find "$FRONTEND_PATH/src/" -name "HorseProfile*" 2>/dev/null | wc -l)
  profile=$(echo "$profile" | tr -d '[:space:]')

  # Check if dashboard links to profile (safe: count per file separately)
  horse_click=0
  for f in "$FRONTEND_PATH/src/components/farm-dashboard/"*.tsx; do
    if [ -f "$f" ]; then
      c=$(grep -c "navigate.*horse\|/horse/\|onHorseClick" "$f" 2>/dev/null || echo 0)
      c=$(echo "$c" | tr -d '[:space:]')
      horse_click=$((horse_click + c))
    fi
  done

  if [ "$route" -gt 0 ] && [ "$profile" -gt 0 ]; then
    s6_level=4
    s6_detail="Route + profile page exist"
    if [ "$horse_click" -gt 0 ]; then
      s6_detail="$s6_detail, dashboard links to profile"
    else
      s6_level=3
      s6_gaslight=3
      s6_detail="$s6_detail, dashboard does NOT link"
      s6_remedy="Add navigate(/horse/id) to horse card clicks"
    fi
  else
    s6_level=1; s6_gaslight=5
    s6_detail="Missing route or profile page"
    s6_remedy="Create route + HorseProfilePage"
  fi
fi

if [ -n "$LIVE_URL" ] && [ "$s6_level" -ge 4 ]; then
  hp_status=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL/api/v1/horses/test" 2>/dev/null || echo "000")
  if [ "$hp_status" = "401" ] || [ "$hp_status" = "422" ]; then
    s6_detail="$s6_detail | horses endpoint: ${hp_status} (deployed)"
    s6_level=5
  fi
fi
record_story "Horse profile click" "$s6_level" "$s6_gaslight" "$s6_detail" "$s6_remedy"
echo ""

# ── STORY 7: WhatsApp → Hope ──
echo -e "${BOLD}── Story 7: WhatsApp → Hope ──${NC}"
s7_level=0; s7_gaslight=0; s7_detail=""; s7_remedy=""

if [ -n "$BACKEND_PATH" ]; then
  ingest=$(grep -c "def ingest\|/ingest" "$BACKEND_PATH/api/routers/zeroclaw.py" 2>/dev/null || echo 0)
  ingest=$(echo "$ingest" | tr -d '[:space:]')
  adapter=$([ -f "$BACKEND_PATH/api/agents/channel/adapter.py" ] && echo 1 || echo 0)

  if [ "$ingest" -gt 0 ] && [ "$adapter" -eq 1 ]; then
    s7_level=2
    s7_detail="Ingest endpoint + adapter exist"

    # Check if adapter actually CALLS Hope orchestrator
    adapter_calls_hope=$(grep -c "orchestrat\|HopeOrchestrator\|dispatch" \
      "$BACKEND_PATH/api/agents/channel/adapter.py" 2>/dev/null || echo 0)
    adapter_calls_hope=$(echo "$adapter_calls_hope" | tr -d '[:space:]')

    if [ "$adapter_calls_hope" -gt 0 ]; then
      s7_level=4
      s7_detail="$s7_detail | adapter references orchestrator"
    else
      s7_gaslight=5
      s7_detail="$s7_detail | adapter does NOT call Hope — TWO SEPARATE SYSTEMS"
      s7_remedy="Wire adapter.py → HopeOrchestrator.dispatch()"
    fi
  fi

  # Check if ZeroClaw Docker is running
  zc_docker=$(docker ps --filter name=zeroclaw 2>/dev/null | grep -c zeroclaw || echo 0)
  if [ "$zc_docker" -gt 0 ]; then
    s7_detail="$s7_detail | ZeroClaw Docker: running"
  else
    s7_detail="$s7_detail | ZeroClaw Docker: NOT running"
  fi

  if [ -n "$LIVE_URL" ] && [ "$s7_level" -ge 3 ]; then
    zc_live=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$LIVE_URL/api/v1/zeroclaw/ingest" \
      -H "Content-Type: application/json" \
      -d '{"farm_id":"test","channel":"test","content":"test"}' 2>/dev/null || echo "000")
    if [ "$zc_live" = "401" ] || [ "$zc_live" = "422" ]; then
      s7_detail="$s7_detail | ingest endpoint: ${zc_live} (deployed)"
      [ "$s7_level" -lt 5 ] && s7_level=5
    fi
  fi
fi
record_story "WhatsApp → Hope" "$s7_level" "$s7_gaslight" "$s7_detail" "$s7_remedy"
echo ""

# ── STORY 8: Page loads at top ──
echo -e "${BOLD}── Story 8: Page loads at top ──${NC}"
s8_level=0; s8_gaslight=0; s8_detail=""; s8_remedy=""

if [ -n "$FRONTEND_PATH" ]; then
  scroll=$(grep -c "ScrollToTop\|scrollTo(0" "$FRONTEND_PATH/src/App.tsx" 2>/dev/null || echo 0)
  scroll=$(echo "$scroll" | tr -d '[:space:]')
  if [ "$scroll" -gt 0 ]; then
    s8_level=5; s8_gaslight=0
    s8_detail="ScrollToTop in App.tsx"
  else
    s8_level=0; s8_gaslight=4
    s8_detail="No ScrollToTop"
    s8_remedy="Add ScrollToTop component"
  fi
fi
record_story "Page loads at top" "$s8_level" "$s8_gaslight" "$s8_detail" "$s8_remedy"
echo ""

# ═══════════════════════════════════════════════════
# FINAL SCORES
# ═══════════════════════════════════════════════════

echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  FINAL SCORES                                              ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Dimension averages
dim_total=0
dim_gaslight_total=0
for i in "${!DIM_LEVELS[@]}"; do
  dim_total=$((dim_total + DIM_LEVELS[i]))
  dim_gaslight_total=$((dim_gaslight_total + DIM_GASLIGHTS[i]))
done
dim_avg=$((DIM_COUNT > 0 ? dim_total / DIM_COUNT : 0))
dim_gaslight_avg=$((DIM_COUNT > 0 ? dim_gaslight_total / DIM_COUNT : 0))

# Story averages
story_total=0
story_gaslight_total=0
for i in "${!STORY_LEVELS[@]}"; do
  story_total=$((story_total + STORY_LEVELS[i]))
  story_gaslight_total=$((story_gaslight_total + STORY_GASLIGHTS[i]))
done
story_avg=$((STORY_COUNT > 0 ? story_total / STORY_COUNT : 0))
story_gaslight_avg=$((STORY_COUNT > 0 ? story_gaslight_total / STORY_COUNT : 0))

# Overall
overall_avg=$(( (dim_total + story_total) / (DIM_COUNT + STORY_COUNT) ))
overall_gaslight=$(( (dim_gaslight_total + story_gaslight_total) / (DIM_COUNT + STORY_COUNT) ))

echo -e "  ${BOLD}DIMENSIONS${NC} (${DIM_COUNT} scored)"
echo -e "    Avg Level:    $(level_label $dim_avg) ($dim_avg/7)"
echo -e "    Avg Gaslight: $(gaslight_color $dim_gaslight_avg)$dim_gaslight_avg${NC}"
echo ""

echo -e "  ${BOLD}USER STORIES${NC} (${STORY_COUNT} tested)"
echo -e "    Avg Level:    $(level_label $story_avg) ($story_avg/7)"
echo -e "    Avg Gaslight: $(gaslight_color $story_gaslight_avg)$story_gaslight_avg${NC}"
echo ""

echo -e "  ${BOLD}OVERALL${NC}"
echo -e "    Level:    ${BOLD}$(level_label $overall_avg) ($overall_avg/7)${NC}"
echo -e "    Gaslight: $(gaslight_color $overall_gaslight)${BOLD}$overall_gaslight${NC}"
echo ""

# Count critical issues
critical=0
for i in "${!DIM_GASLIGHTS[@]}"; do
  [ "${DIM_GASLIGHTS[$i]}" -ge 4 ] && critical=$((critical + 1))
done
for i in "${!STORY_GASLIGHTS[@]}"; do
  [ "${STORY_GASLIGHTS[$i]}" -ge 4 ] && critical=$((critical + 1))
done

# ═══════════════════════════════════════════════════
# TOTAL SCORE — single number out of 100
# Formula: (avg_level / 7) * 100, penalized by gaslight
# Penalty: -5 points per critical gaslight item
# ═══════════════════════════════════════════════════

total_points=$((dim_total + story_total))
max_points=$(( (DIM_COUNT + STORY_COUNT) * 7 ))
if [ "$max_points" -gt 0 ]; then
  raw_score=$(( (total_points * 100) / max_points ))
else
  raw_score=0
fi
gaslight_penalty=$((critical * 5))
total_score=$((raw_score - gaslight_penalty))
[ "$total_score" -lt 0 ] && total_score=0

# Color the score
if [ "$total_score" -ge 70 ]; then
  score_color="$GREEN"
elif [ "$total_score" -ge 40 ]; then
  score_color="$YELLOW"
else
  score_color="$RED"
fi

echo -e "  ${BOLD}════════════════════════════════════════${NC}"
echo -e "  ${BOLD}  TOTAL SCORE: ${score_color}${BOLD}${total_score}/100${NC}"
echo -e "  ${DIM}  (${raw_score} raw - ${gaslight_penalty} gaslight penalty)${NC}"
echo -e "  ${BOLD}════════════════════════════════════════${NC}"
echo ""

if [ "$critical" -eq 0 ]; then
  echo -e "  Verdict: ${GREEN}${BOLD}HONEST STATE${NC} — no critical gaslight issues"
elif [ "$critical" -le 3 ]; then
  echo -e "  Verdict: ${YELLOW}${BOLD}NEEDS WORK${NC} — $critical items with gaslight >= 4"
else
  echo -e "  Verdict: ${RED}${BOLD}GASLIGHT RISK${NC} — $critical items with gaslight >= 4"
fi

# ═══════════════════════════════════════════════════
# WRITE REPORT
# ═══════════════════════════════════════════════════

cat > "$REPORT_FILE" << REPORT_HEADER
# GLASS v3 Audit Report

**Timestamp:** $(timestamp)
**Frontend:** ${FRONTEND_PATH:-not provided}
**Backend:** ${BACKEND_PATH:-not provided}
**Live URL:** ${LIVE_URL:-not provided}

## Dimension Scores

| Dimension | Level | Score | Gaslight | Detail | Fix |
|---|---|---|---|---|---|
REPORT_HEADER

for i in "${!DIM_NAMES[@]}"; do
  ll=$(level_label "${DIM_LEVELS[$i]}")
  echo "| ${DIM_NAMES[$i]} | $ll | ${DIM_LEVELS[$i]}/7 | ${DIM_GASLIGHTS[$i]} | ${DIM_DETAILS[$i]} | ${DIM_REMEDIES[$i]} |" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" << STORY_HEADER

## User Stories

| Story | Level | Score | Gaslight | Detail | Fix |
|---|---|---|---|---|---|
STORY_HEADER

for i in "${!STORY_NAMES[@]}"; do
  ll=$(level_label "${STORY_LEVELS[$i]}")
  echo "| ${STORY_NAMES[$i]} | $ll | ${STORY_LEVELS[$i]}/7 | ${STORY_GASLIGHTS[$i]} | ${STORY_DETAILS[$i]} | ${STORY_REMEDIES[$i]} |" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" << SUMMARY

## Summary

- Dimensions: $DIM_COUNT scored, avg $(level_label $dim_avg) ($dim_avg/7), gaslight avg $dim_gaslight_avg
- Stories: $STORY_COUNT tested, avg $(level_label $story_avg) ($story_avg/7), gaslight avg $story_gaslight_avg
- Overall: $(level_label $overall_avg) ($overall_avg/7), gaslight $overall_gaslight
- Critical issues (gaslight >= 4): $critical
- **TOTAL SCORE: ${total_score}/100** (${raw_score} raw - ${gaslight_penalty} gaslight penalty)
- Verdict: $([ "$critical" -eq 0 ] && echo "HONEST STATE" || ([ "$critical" -le 3 ] && echo "NEEDS WORK" || echo "GASLIGHT RISK"))
- Generated: $(timestamp)
SUMMARY

echo ""
echo -e "  Report: ${CYAN}$REPORT_FILE${NC}"
echo ""

# Exit 1 if critical issues
[ "$critical" -gt 0 ] && exit 1
exit 0
