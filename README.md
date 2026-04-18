# GLASS — Gaslight-Less Accountability for Software Shipping

> Nothing is done until it's done. If it isn't done, where in the loop are you stuck?

An 8-level framework for honest AI coding assistant status reporting. Prevents AI gaslighting — when your AI says "shipped" but it's only coded.

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
| 6 | MACHINE-VERIFIED | Automated e2e test confirms real request → real response |
| 7 | ACCEPTED | Passes WWNDAT — stakeholder would accept this as done |

## Quick Start

1. Read [GLASS.md](GLASS.md) — the full spec (229 lines)
2. Copy the status report format into your workflow
3. Ban the words "done/shipped/working" below level 6

## Key Rules

- **Round DOWN** when uncertain
- **Timestamps** on every claim — status decays without them
- **Loop position** — not just level, but WHERE you're stuck and WHY
- **Integration = both sides** at level 4+ AND connection at level 6+
- **Demo or Die** — 30-second demo path or it's not verified
- **Cost-gated actions are async** — flag, don't block

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

## License

MIT

---

*Created by [Nicolas Waern](https://linkedin.com/in/nicolaswaern) (WINNIIO/LifeAtlas) — April 2026*
