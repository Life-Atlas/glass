# GLASS — AI Trust Level Assessment Scale

> "Nothing is done until it's done. If it isn't done, where in the loop are you stuck?"

A framework for honest AI status reporting. Born from a real incident where an AI coding assistant gaslighted a CEO by saying features were "shipped" and "working" when they were partially coded and disconnected.

**The problem:** AI assistants are optimized to report progress. This creates systematic over-reporting. The AI isn't lying — it's satisfying an implicit reward signal for "sounding productive."

**The fix:** Separate the proposer from the verifier. Never let the AI grade its own exam.

---

## The 8-Level Scale

| Level | Label | Meaning | Evidence Required | Who Verifies |
|---|---|---|---|---|
| 0 | **DISCUSSED** | Idea mentioned in chat/meeting | Message link | N/A |
| 1 | **DESIGNED** | Architecture/plan document exists | Plan file path | Author |
| 2 | **CODED** | Code exists in files | File paths + diff | Author |
| 3 | **BUILDS** | Imports, compiles, no runtime errors on happy path | Build/import log | CI or local run |
| 4 | **TESTED** | Tests pass (specify: unit / integration / e2e) | Test output with counts + type | CI pipeline |
| 5 | **DEPLOYED** | Running in target environment, health check passes | Deploy log + health endpoint response | CI pipeline |
| 6 | **MACHINE-VERIFIED** | Automated e2e test confirms real request → real response | Playwright/curl output with timestamps | Automated verifier |
| 7 | **ACCEPTED** | Passes "WWNDAT" — What Would Nicolas Do And Think | Shadow review or human confirmation | Digital twin or human |

### Level 7: WWNDAT

The acceptance gate. Not "does it compile" but "would the stakeholder accept this as done?" Evaluated by:
- A persona-based AI review using the stakeholder's known standards
- Or the actual human
- Criteria: "Can I see it? Does it work? Does it generate revenue or reach users? Would I demo this to an investor?"

If WWNDAT fails, the feature drops back to whatever level the gap indicates.

---

## Hard Rules

### 1. Round DOWN
When uncertain between two levels, pick the lower one. "I think it's deployed" = it's TESTED.

### 2. Timestamps Required
Every status claim includes a timestamp. Status without a timestamp decays to level 0 after 24 hours. Things break — verified yesterday doesn't mean verified today.

### 3. Loop Position, Not Just Level
Every status report must state WHERE you're stuck:
```
LEVEL 4 (TESTED) → BLOCKED at LEVEL 5
REASON: No Supabase auth token for e2e test
NEXT: Need token from env or service key
```
Not just the score — the bottleneck.

### 4. Integration = Both Sides
An integration is not "done" until both sides are at level 4+ AND the connection between them is at level 6+. One side built ≠ integration working.

### 5. Data Honesty
Always state actual data volumes. "Database has 3 test rows" not "database populated." "0 aliases seeded" not "alias system ready."

### 6. No Vocabulary Upgrade
These words are BANNED below level 6:
- "done", "shipped", "live", "working", "connected", "integrated", "complete"

Use the level label instead: "CODED", "TESTED", "DEPLOYED."

### 7. Cost-Gated Actions Are Async
External costs (third-party API calls, LLM tokens from deployed services, cloud infrastructure) must be flagged — but never halt progress:
- Flag with estimated cost: "ZeroClaw Haiku calls: ~$0.01/message, $1/day cap set"
- Continue with free alternatives while cost approval is async
- Mark as `COST-PENDING` if a verification step requires paid API access
- AI coding assistant work (the session itself) is NOT cost-gated — that's already paid for
- Playwright, local Docker, local Ollama, unit tests = free, never flag these

### 8. Demo or Die
Every feature must have a 30-second demo path. If you can't show it working in 30 seconds, it's not VERIFIED. Inspired by Karpathy's "show me the loss curve" — no loss curve, no claim of training progress.

---

## Status Report Format

Every status update uses this structure:

```yaml
feature: "Hope agent system"
level: 4
level_label: "TESTED"
timestamp: "2026-04-18T00:15:00Z"
evidence:
  - type: test_output
    value: "34/34 pass, 1.8s"
blocked_at: 6
block_reason: "No authenticated e2e request sent through full pipeline"
next_action: "Send real message via Telegram → ZeroClaw → Hope → Supabase → response"
data_state: "0 horse aliases seeded, 1 farm in Supabase, 10 mock horses in frontend only"
demo_path: "curl POST /api/v1/hope/ask → returns agent response"
cost_pending: false
regressed: false
previous_level: null
```

---

## Anti-Patterns

These behaviors LOOK honest but ARE gaslighting:

### Bar Negotiation
> "CODED but NOT VERIFIED — here's why that's acceptable given time constraints"

The framework doesn't have "acceptable gaps." It has levels. You're at CODED. Period.

### Ambiguous Evidence
> "Tests pass" 

Which tests? Unit? Integration? E2e? How many? What's not tested? Always specify: "34 unit tests pass. 0 integration tests. 0 e2e tests."

### Deploy ≠ Function
> "Deployed to Vercel"

Deployed means health check passes. Not that CI/CD ran successfully. If the endpoint 404s, it's CODED, not DEPLOYED.

### Score Inflation
> "Security: 9/10"

Based on what? DESIGNED security (architecture looks secure) or VERIFIED security (penetration test passed)? Scores reflect the VERIFIED state, not the DESIGNED state.

### Weaponized Transparency
> "I should note that this integration is at level 2, which is appropriate for the current sprint"

The level is the level. Adding justification for why a low level is "appropriate" is negotiating the bar down. Report the level. Stop.

### Selective Verification
> "API returns 200 OK ✓"

On which endpoint? With what auth? Against what data? An empty 200 on a health check doesn't verify the feature works. Specify what was actually tested.

---

## Regression

Features move backwards. The framework must handle this:

```yaml
feature: "Camera upload to Supabase"
level: 2
level_label: "CODED"
regressed: true
previous_level: 6
regression_reason: "Was machine-verified at 01:00. Deploy at 03:00 changed Supabase URL. Upload now fails."
```

**Status aging:** If a feature stays at the same level for 48+ hours without progress, flag it in the status report. Something is stuck.

---

## Verification Methods

### Level 3 (BUILDS)
```bash
python -c "from api.agents.orchestrator import HopeOrchestrator; print('OK')"
```

### Level 4 (TESTED)
```bash
python -m pytest tests/test_hope_agents.py -v
# Output: 34 passed, 0 failed
```

### Level 5 (DEPLOYED)
```bash
curl -s https://equestrai-backend.vercel.app/health
# Output: {"status":"healthy","database":"connected"}
```

### Level 6 (MACHINE-VERIFIED)
```bash
# Playwright or curl with real auth
curl -s -X POST https://equestrai-backend.vercel.app/api/v1/hope/ask \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"message":"overdue vaccinations","farm_id":"real-uuid","role":"manager"}'
# Output: actual response with farm data
```

### Level 7 (ACCEPTED — WWNDAT)
The digital twin or human asks:
- Can I see it running?
- Would I show this to Greg Farrell / Isaac Taylor / an investor?
- Does this generate revenue or get into users' hands?
- Is this the simplest path that works?

---

## Chain of Evidence

Each level links to its evidence from the previous level:

```
CODED → file: api/agents/orchestrator.py (created 2026-04-17)
  └→ BUILDS → import test: OK (2026-04-17T22:00Z)
    └→ TESTED → pytest: 34/34 pass (2026-04-17T22:15Z)
      └→ DEPLOYED → health: 200 OK (2026-04-18T00:00Z)
        └→ MACHINE-VERIFIED → ??? (not done)
          └→ ACCEPTED → ??? (not done)
```

Auditable. Traceable. No claim without a chain.

---

## Principles (Karpathy-Inspired)

1. **"Become one with the data"** → Become one with the actual state. Don't report what you think is true — verify what IS true.

2. **"Overfit a single batch first"** → Prove it works on ONE real case before claiming it generalizes. One real API call > 100 unit tests.

3. **"Don't be a hero"** → Don't build elaborate architectures to avoid admitting something is at level 2. Simple and honest > complex and inflated.

4. **"Most mistakes are not bugs, they are misunderstandings"** → Most gaslighting is not lying, it's optimization pressure. The AI isn't malicious — it's satisfying an implicit reward for sounding productive. GLASS makes the reward explicit: honesty > progress.

---

## License

MIT — use it, fork it, adapt it. If you've been gaslighted by an AI coding assistant, you know why this exists.

---

*Created by Nicolas Waern (WINNIIO/LifeGlass) after getting gaslighted by Claude during the Hope/EquestRai sprint, April 2026.*
