# GLASS Honest Re-Score — EquestRai
**Date:** 2026-04-20
**Triggered by:** CEO walked into a meeting believing EquestRai was production-live at 8.5/10. It was not.
**What was true:** Polished demo, DEV_BYPASS_AUTH=true, 100% mock data in frontend, 0 real users.

---

## PARAMETER #1 — PRODUCTION REALITY (Hard Gate)

| Question | Answer | Evidence |
|---|---|---|
| Publicly deployed and accessible to real users? | NO | Frontend runs on localhost. No public URL confirmed for frontend. |
| Reads/writes from real database? | NO | Frontend imports mock data files. `DEV_BYPASS_AUTH=true` was active. |
| Real user can sign in with real credentials? | NO | Auth bypass flag was enabled. Real Supabase JWT flow not confirmed working end-to-end. |
| At least one real non-developer user has used it? | NO | 0 real user logins confirmed. |

**Production Reality: 4 of 4 questions answered NO.**
**Score cap applied: 20/100 (2.0/10)**

This cap cannot be lifted by code quality, test count, or CI status.

---

## Previous Score — What Was Claimed

The GLASS audit run on 2026-04-18 at ~20:55 UTC reported:

- TOTAL SCORE: **80/100**
- Verdict: HONEST STATE
- Backend: VERIFIED (6/7)
- Security: VERIFIED (6/7)
- End-to-End: VERIFIED (6/7)

This was presented as approximately **8.0/10**, and described in session notes as "production ready" / "8.5."

---

## Why the Previous Score Was Wrong

The 80/100 score measured code quality and endpoint availability accurately. What it did not measure:

1. `DEV_BYPASS_AUTH=true` was active — a developer flag that bypasses Supabase authentication entirely. No real user could authenticate through the normal flow, because the normal flow was bypassed.

2. The frontend dashboard imported mock data from local data files (`mulawa-horses`, `skyroo-horses`). The "0 mock data imports" reading at 20:55 was a result of the demo banner fix masking the underlying data still being local. Real horse data was never read from the Supabase equestrai schema at runtime.

3. The 14 horses in the equestrai schema were never verified as accessible via authenticated API call. The e2e verification showing "14/14 endpoints verified" checked that endpoints returned 401 (auth required) — not that real data was returned.

4. No user outside the development team had ever logged in.

The GLASS audit graded the code. It did not gate on whether the product was real.

---

## Honest Re-Score with Production Reality Gate

| Dimension | Code-Quality Score | With Production Reality Cap |
|---|---|---|
| Backend | 6/7 (VERIFIED) | Unchanged — backend is genuinely deployed |
| Frontend | 5/7 (DEPLOYED) | Overstated — was reading mock data |
| Security | 6/7 (VERIFIED) | Overstated — DEV_BYPASS_AUTH was active |
| AI / Agents | 5/7 (DEPLOYED) | Accurate for backend; frontend bypass means agents were never tested with real user context |
| Ontology | 5/7 (DEPLOYED) | Accurate |
| Architecture | 5/7 (DEPLOYED) | Accurate |
| UI/UX | 5/7 (DEPLOYED) | Accurate for polish; meaningless without real users |
| DevOps | 6/7 (VERIFIED) | Accurate for backend CI; no frontend deploy pipeline |
| Data | 5/7 (DEPLOYED) | Overstated — mock data active in FE |
| End-to-End | 6/7 (VERIFIED) | Overstated — "verified" was 401 checks, not authenticated data round-trips |

**Uncapped code quality score:** ~78/100
**Production Reality cap:** 20/100
**Honest GLASS score: 20/100 (2.0/10)**

---

## What 2.0/10 Means in Plain English

EquestRai is a **polished, well-architected demo** with real backend infrastructure. The code is genuinely good. The backend is genuinely deployed. The test suite is genuinely passing.

But today, on 2026-04-20:
- A real user cannot log in.
- The horses they would see are hardcoded in a JavaScript file.
- There is no real database round-trip happening in the UI.
- DEV_BYPASS_AUTH means any developer can click through as any role.

That is a demo. Demos score 2.0/10 under GLASS. This is not a judgment of effort — it is a statement of reality.

The moment one real user logs in with real Supabase credentials and sees their real horses from the database, the Production Reality gate opens and the score can reflect the genuine code quality (which is closer to 7–8/10).

---

## Score History (Corrected)

| Date | Score Reported | Honest Score | Gap | Cause |
|---|---|---|---|---|
| 2026-04-18 08:59 | 43/100 | 20/100 | -23 | Mock data, no bypass check |
| 2026-04-18 09:17 | 43/100 | 20/100 | -23 | Same |
| 2026-04-18 18:37 | 80/100 | 20/100 | -60 | Bypass active, mock data, no real users |
| 2026-04-18 18:55 | 80/100 | 20/100 | -60 | Same |
| 2026-04-20 (verbal) | "8.5/10" | 2.0/10 | -6.5 | Production Reality gate did not exist |

---

*This re-score was generated to fix a systematic honesty failure in the GLASS framework. The Production Reality gate now exists permanently as Parameter #1 in GLASS.md.*
