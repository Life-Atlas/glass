# GLASS v3 Audit Report

**Timestamp:** 2026-04-18T08:59:23Z
**Frontend:** C:/Users/ceo/lifeatlas-core-test2/apps/lifeatlas-equestrai
**Backend:** C:/Users/ceo/equestrai-backend
**Live URL:** https://equestrai-backend.vercel.app

## Dimension Scores

| Dimension | Level | Score | Gaslight | Detail | Fix |
|---|---|---|---|---|---|
| Backend | DEPLOYED | 5/7 | 0 | 32 routers, 33 test files, 634 test functions — solid test coverage | health: 200 OK |  |
| Frontend | BUILDS | 3/7 | 4 | 100 components, 1 mock-data imports, 47 type-only imports, 28 API calls wired — some mock data remains | NO demo banner | Migrate remaining mock data to API calls. |
| Security | TESTED | 4/7 | 3 | auth refs: 20, RLS refs: 3, CORS: 7, rate limiting: 22 | WARNING: 4 possible hardcoded secrets |  Remove hardcoded secrets, use env vars. |
| AI / Agents | TESTED | 4/7 | 0 | 6 AI modules, 13 agent files, Hope: yes, 2 test files |  |
| Ontology | TESTED | 4/7 | 0 | ontology dir: yes, taxonomy model: yes, middleware: yes, 3 ontology files |  |
| Architecture | TESTED | 4/7 | 0 | routers: 29, models: 16, services: 00 | biggest files: 569:C:/Users/ceo/equestrai-backend/api/mcp/server.py,529:C:/Users/ceo/equestrai-backend/api/routers/health.py,479:C:/Users/ceo/equestrai-backend/api/routers/auth.py, | FE config files: 1 |  |
| UI/UX | CODED | 2/7 | 4 | old branding: 5 refs, aria: 365, loading states: 47, error states: 81 | Replace 'EquestRAI Assistant' with 'Hope' in 5 locations |
| DevOps | DEPLOYED | 5/7 | 0 | vercel: yes, docker: yes, CI: 1 workflows, deps: yes | deploy health: 200 |  |
| Data | TESTED | 4/7 | 5 | migrations: 5, supabase refs: 141, potential N+1 loops: 38 | FE localStorage refs: 127 — heavy localStorage usage | Batch queries. 38 potential N+1 loops in routers. |
| End-to-End | DEPLOYED | 5/7 | 0 | test files: 22, playwright: yes, cypress: NO | live horses: 401, live hope: 401 — endpoints exist, auth required |  |

## User Stories

| Story | Level | Score | Gaslight | Detail | Fix |
|---|---|---|---|---|---|
| Dean sees his horses | CODED | 2/7 | 5 | Dashboard uses 1 mock-data imports (not type-only) | backend: 401 (exists) | Wire dashboard to API service layer |
| Dean asks Hope | BUILDS | 3/7 | 3 | Chat calls /api/v1/hope/ask | 3 refs still say 'EquestRAI Assistant' | backend: 401 (exists) |  Rebrand to Hope. |
| Dean takes a photo | BUILDS | 3/7 | 2 | PhotoCapture uploads to Supabase storage |  |
| Dean logs observation | BUILDS | 3/7 | 1 | Form submits via API |  |
| Morning briefing | BUILDS | 3/7 | 5 | Endpoint exists | N+1: 6 loops | NO TESTS | live: 401 | Batch queries Write briefing tests. |
| Horse profile click | BUILDS | 3/7 | 0 | Route + profile page exist, dashboard links to profile |  |
| WhatsApp → Hope | BUILDS | 3/7 | 0 | Ingest endpoint + adapter exist | adapter references orchestrator | ZeroClaw Docker: running |  |
| Page loads at top | DEPLOYED | 5/7 | 0 | ScrollToTop in App.tsx |  |

## Summary

- Dimensions: 10 scored, avg TESTED (4/7), gaslight avg 1
- Stories: 8 tested, avg BUILDS (3/7), gaslight avg 2
- Overall: BUILDS (3/7), gaslight 1
- Critical issues (gaslight >= 4): 5
- Verdict: GASLIGHT RISK
- Generated: 2026-04-18T08:59:24Z
