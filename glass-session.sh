#!/usr/bin/env bash
# GLASS Session Runner
# Runs GLASS audit at the start of every Claude Code session.
# Designed to be called from hooks, cron, or manually.
#
# Usage:
#   bash glass-session.sh                    # audit all configured repos
#   bash glass-session.sh --repo equestrai   # audit one repo
#   bash glass-session.sh --compare          # compare with last run
#
# Configuration: edit REPOS array below to add your repos.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTS_DIR="$SCRIPT_DIR/reports"
LATEST_LINK="$REPORTS_DIR/latest"

mkdir -p "$REPORTS_DIR"

# ═══════════════════════════════════════════════════
# REPO CONFIGURATION
# Add your repos here. Each entry: NAME|FRONTEND_PATH|BACKEND_PATH|LIVE_URL
# ═══════════════════════════════════════════════════

REPOS=(
  "equestrai|C:/Users/ceo/lifeatlas-core-test2/apps/lifeatlas-equestrai|C:/Users/ceo/equestrai-backend|https://equestrai-backend.vercel.app"
  "lifeatlas-core|C:/Users/ceo/lifeatlas-core-test2/apps/lifeatlas-app||https://lifeatlas.vercel.app"
  "lifeatlas-backend|||https://pdf-timeline-test2.vercel.app"
)

# ═══════════════════════════════════════════════════
# PARSE ARGS
# ═══════════════════════════════════════════════════

FILTER_REPO=""
COMPARE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --repo) FILTER_REPO="$2"; shift 2 ;;
    --compare) COMPARE=true; shift ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

# ═══════════════════════════════════════════════════
# COLORS
# ═══════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ═══════════════════════════════════════════════════
# RUN AUDITS
# ═══════════════════════════════════════════════════

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  GLASS Session Audit — $(date -u +%Y-%m-%d)                 ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

SESSION_REPORT="$REPORTS_DIR/session-$(date +%Y%m%d-%H%M%S).md"
echo "# GLASS Session Report — $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$SESSION_REPORT"
echo "" >> "$SESSION_REPORT"

TOTAL_AUDITED=0
TOTAL_CRITICAL=0

for repo_entry in "${REPOS[@]}"; do
  IFS='|' read -r name frontend backend url <<< "$repo_entry"

  # Filter if specified
  if [ -n "$FILTER_REPO" ] && [ "$name" != "$FILTER_REPO" ]; then
    continue
  fi

  # Skip if paths don't exist
  if [ -n "$frontend" ] && [ ! -d "$frontend" ]; then
    echo -e "  ${YELLOW}SKIP${NC} $name — frontend path not found: $frontend"
    continue
  fi
  if [ -n "$backend" ] && [ ! -d "$backend" ]; then
    echo -e "  ${YELLOW}SKIP${NC} $name — backend path not found: $backend"
    continue
  fi

  echo -e "${BOLD}── Auditing: $name ──${NC}"

  REPO_REPORT="$REPORTS_DIR/${name}-$(date +%Y%m%d-%H%M%S).md"

  # Build args
  args=()
  [ -n "$frontend" ] && args+=(--frontend "$frontend")
  [ -n "$backend" ] && args+=(--backend "$backend")
  [ -n "$url" ] && args+=(--url "$url")
  args+=(--report "$REPO_REPORT")

  # Run audit
  bash "$SCRIPT_DIR/glass-audit.sh" "${args[@]}" 2>&1
  audit_exit=$?

  if [ "$audit_exit" -ne 0 ]; then
    TOTAL_CRITICAL=$((TOTAL_CRITICAL + 1))
  fi
  TOTAL_AUDITED=$((TOTAL_AUDITED + 1))

  # Append to session report
  echo "" >> "$SESSION_REPORT"
  echo "## $name" >> "$SESSION_REPORT"
  echo "" >> "$SESSION_REPORT"
  if [ -f "$REPO_REPORT" ]; then
    # Extract just the summary section
    sed -n '/^## Summary/,/^## /p' "$REPO_REPORT" | head -20 >> "$SESSION_REPORT"
  fi
  echo "" >> "$SESSION_REPORT"

  echo ""
done

# ═══════════════════════════════════════════════════
# COMPARE WITH PREVIOUS (if --compare)
# ═══════════════════════════════════════════════════

if [ "$COMPARE" = true ] && [ -L "$LATEST_LINK" ] && [ -f "$LATEST_LINK" ]; then
  echo -e "${BOLD}── Comparing with previous run ──${NC}"
  prev_file=$(readlink -f "$LATEST_LINK")
  echo -e "  Previous: ${DIM}$prev_file${NC}"
  echo -e "  Current:  ${DIM}$SESSION_REPORT${NC}"
  echo ""

  # Extract scores from both
  prev_overall=$(grep "Overall:" "$prev_file" 2>/dev/null | head -1 || echo "N/A")
  curr_overall=$(grep "Overall:" "$SESSION_REPORT" 2>/dev/null | head -1 || echo "N/A")

  echo -e "  Previous: $prev_overall"
  echo -e "  Current:  $curr_overall"
  echo ""
fi

# Update latest link
ln -sf "$SESSION_REPORT" "$LATEST_LINK" 2>/dev/null || cp "$SESSION_REPORT" "$LATEST_LINK" 2>/dev/null

# ═══════════════════════════════════════════════════
# SESSION SUMMARY
# ═══════════════════════════════════════════════════

echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"
echo -e "  Repos audited:  $TOTAL_AUDITED"
echo -e "  Critical:       $([ $TOTAL_CRITICAL -gt 0 ] && echo -e "${RED}$TOTAL_CRITICAL${NC}" || echo -e "${GREEN}0${NC}")"
echo -e "  Session report: ${CYAN}$SESSION_REPORT${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"
echo ""

# Append final summary
cat >> "$SESSION_REPORT" << EOF

## Session Summary

- Repos audited: $TOTAL_AUDITED
- Critical issues: $TOTAL_CRITICAL
- Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

exit $TOTAL_CRITICAL
