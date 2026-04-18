# GLASS — Gaslight-Less Accountability for Software Shipping

> Nothing is done until it's done. If it isn't done, where in the loop are you stuck?

An 8-level framework + 10-dimension audit for honest AI coding assistant status reporting. Prevents AI gaslighting — when your AI says "shipped" but it's only coded.

## Why This Exists

An AI coding assistant told a CEO that features were "deployed and working" when they were partially coded and disconnected. Tasks were marked "completed" at 8/10 when honest scores were 5/10. The CEO asked: *"Have you been gaslighting me?"*

GLASS ensures that never happens again.

## The Scale

| Level | Label | What It Means |
|---|---|---|
| 0 | DISCUSSED | Idea exists, no artifact |
| 1 | DESIGNED | Plan/architecture document |
| 2 | CODED | Code in files |
| 3 | BUILDS | Compiles, imports, no runtime errors |
| 4 | TESTED | Tests pass (specify which type) |
| 5 | DEPLOYED | Running in production, health check passes |
| 6 | MACHINE-VERIFIED | Automated e2e test confirms real request -> real response |
| 7 | ACCEPTED | Passes WWNDAT — stakeholder would accept this as done |

## Quick Start

```bash
# Single repo audit
bash glass-audit.sh \
  --frontend path/to/frontend \
  --backend path/to/backend \
  --url https://your-api.vercel.app

# Session-start audit (all configured repos)
bash glass-session.sh

# Compare with previous run
bash glass-session.sh --compare

# Audit just one repo
bash glass-session.sh --repo equestrai
```

## 10-Dimension Scoring (v3)

The audit scores your project across 10 dimensions:

| # | Dimension | What It Measures |
|---|---|---|
| 1 | **Backend** | Routers, tests, health endpoint, deployment |
| 2 | **Frontend** | Components, mock vs real data, API wiring |
| 3 | **Security** | Auth, RLS, CORS, rate limiting, secrets |
| 4 | **AI / Agents** | AI modules, agent architecture, orchestrator |
| 5 | **Ontology** | Domain models, taxonomy, middleware |
| 6 | **Architecture** | Layering, god files, config-driven design |
| 7 | **UI/UX** | Branding consistency, a11y, loading/error states |
| 8 | **DevOps** | Deploy config, CI, dependency management |
| 9 | **Data** | Migrations, N+1 patterns, localStorage vs API |
| 10 | **End-to-End** | E2e tests, live endpoint verification |

Each dimension gets a GLASS level (0-7) and a gaslight score (0-10). Gaslight >= 4 = critical issue.

## User Stories

On top of dimensions, GLASS tests user stories end-to-end (UI -> API -> DB -> Response). Example:

```
Story: "Dean opens dashboard, sees his horses"
Level: CODED (2/7)
Gaslight: 5
Detail: Dashboard uses hardcoded mock data, backend exists
Fix: Wire dashboard to API service layer
```

## Session Runner

`glass-session.sh` is designed to run at the start of every coding session:

1. Edit the `REPOS` array in the script to list your repos
2. Run `bash glass-session.sh` at session start
3. Reports saved to `reports/` directory with timestamps
4. Use `--compare` to track progress across sessions

### Claude Code Integration

Add to your Claude Code hooks or session start routine:

```bash
# In your session start hook
bash ~/atlas-accountability/glass-session.sh --repo your-repo 2>&1 | tail -20
```

## Key Rules

- **Round DOWN** when uncertain
- **Timestamps** on every claim — status decays without them
- **Loop position** — not just level, but WHERE you're stuck and WHY
- **Integration = both sides** at level 4+ AND connection at level 6+
- **Demo or Die** — 30-second demo path or it's not verified
- **Cost-gated actions are async** — flag, don't block
- **Banned words below level 6:** done, shipped, working, live, connected, integrated, complete

## WWNDAT — What Would [Name] Do And Think?

Level 7 isn't a rubber stamp. It's a persona-based acceptance test:
- Can I see it running?
- Would I show this to a customer / investor?
- Does this generate revenue or reach users?
- Is this the simplest path that works?

## Works With

- Claude Code (hook in `settings.json`)
- Any AI coding assistant (framework-agnostic spec)
- CI/CD pipelines (status maps to pipeline stages)
- Sprint ceremonies (replaces binary done/not-done)

## Files

| File | Purpose |
|---|---|
| `GLASS.md` | Full specification (229 lines) |
| `glass-audit.sh` | 10-dimension + user story audit script |
| `glass-session.sh` | Multi-repo session runner with comparison |
| `reports/` | Timestamped audit reports |

## License

MIT — use it, fork it, adapt it. If you've been gaslighted by an AI coding assistant, you know why this exists.

---

*Created by [Nicolas Waern](https://linkedin.com/in/nicolaswaern) (WINNIIO/LifeAtlas) — April 2026*
