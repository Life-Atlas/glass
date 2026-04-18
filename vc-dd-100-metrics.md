# Hostile VC Due Diligence — 100-Metric Platform Roast

**Date:** 2026-04-18  
**Target:** EquestRai (Skyroo Arabians pilot)  
**Backend:** https://equestrai-backend.vercel.app (101 endpoints)  
**Frontend:** https://lifeatlas-equestrai.vercel.app  
**Auditors:** Security, DevOps, AI Architect, AWS Architect, Scrum Master, BE Dev, FE Dev, Pen Tester, Stress Tester, UX Specialist  

---

## A. BACKEND (20 metrics)

| # | Metric | Score | Evidence | Fix to 10 |
|---|---|---|---|---|
| A1 | API endpoint coverage | 9/10 | 101 endpoints, 105 schemas, full CRUD on all entities | Add WebSocket real-time events endpoint |
| A2 | Input validation | 8/10 | 115 pydantic validation refs, Field constraints, validators | Add request body size limits globally |
| A3 | Error handling | 6/10 | 25 broad `except Exception` catches, 0 bare excepts | Replace with specific exceptions, add error codes |
| A4 | Pagination | 8/10 | 70 pagination refs, limit/offset on all list endpoints | Add cursor-based pagination for large datasets |
| A5 | Rate limiting | 7/10 | 14 rate limit refs across routers, per-endpoint limits | Add rate limiting to ALL endpoints, not just some |
| A6 | Test coverage | 7/10 | 644 tests, 12.7K test lines, ~84% line ratio | Run actual coverage report, target 90%+ |
| A7 | API documentation | 8/10 | Auto-generated OpenAPI at /docs, 101 paths documented | Add example responses, error schemas |
| A8 | Code organization | 7/10 | Clean router/model separation, but 6 files >400 lines | Split health.py (529 lines), auth.py (479 lines) |
| A9 | Logging & observability | 7/10 | structlog configured, 223 log statements, request logging middleware | Add Sentry, add correlation IDs, add APM |
| A10 | Database access patterns | 6/10 | Supabase client, 4 N+1 patterns remain, no connection pooling | Fix N+1s, add pgbouncer or Supabase pooler |
| A11 | Response consistency | 7/10 | Most endpoints return typed models, some return raw dicts | Standardize all responses with envelope pattern |
| A12 | Dependency freshness | 8/10 | FastAPI >=0.115, Pydantic >=2.0, all major deps current | Add pip-audit to CI (done), pin exact versions |
| A13 | Health check | 9/10 | /health returns status + DB connection + version | Add dependency health (Redis, Stripe, external APIs) |
| A14 | Async performance | 7/10 | Mix of sync/async handlers, Supabase client is sync | Migrate to async Supabase client |
| A15 | GraphQL | 6/10 | Strawberry GraphQL endpoint exists, basic schema | Complete schema, add subscriptions for real-time |
| A16 | WebSocket | 5/10 | ws_router exists for sensor data, basic implementation | Add auth to WebSocket, add reconnection, add rooms |
| A17 | Versioning | 5/10 | All routes under /api/v1/, no v2 strategy | Add API version negotiation, deprecation headers |
| A18 | Idempotency | 4/10 | No idempotency keys on mutations | Add idempotency-key header support for POST/PUT |
| A19 | Caching | 3/10 | No cache layer, no ETags, no Cache-Control | Add Redis cache for read-heavy endpoints |
| A20 | Background jobs | 4/10 | No task queue, briefing computed on-request | Add Celery/ARQ for async tasks (briefing, reports) |

**Backend Average: 6.5/10**

---

## B. FRONTEND (15 metrics)

| # | Metric | Score | Evidence | Fix to 10 |
|---|---|---|---|---|
| B1 | Component architecture | 8/10 | 100 components, clean separation, config-driven farms | Extract shared hooks into library |
| B2 | Type safety | 8/10 | Only 3 `any` types in entire codebase | Eliminate remaining 3 any types |
| B3 | State management | 7/10 | React Query for server state, context for app state | Add optimistic updates, cache invalidation strategy |
| B4 | Mock data dependency | 5/10 | 80KB mock data shipped in bundle, 47 type-only imports | Tree-shake mock data in prod build, lazy-load |
| B5 | Test coverage | 4/10 | 18 test files for 100 components (18% coverage) | Add component tests with Testing Library |
| B6 | Build health | 3/10 | Tailwind @apply error blocks vite build, dev server works | Fix border-border class, verify prod build |
| B7 | Bundle size | 5/10 | 80KB mock data + 15 lazy-loaded pages, no bundle analysis | Run bundle analyzer, code-split mock data |
| B8 | Error handling | 7/10 | 41 ErrorBoundary refs, error states in components | Add global error boundary with Sentry reporting |
| B9 | Loading states | 8/10 | 47 loading state refs, skeleton patterns used | Consistent loading skeleton across all pages |
| B10 | Console output | 6/10 | 16 console.log statements in production code | Remove all console.log, use structured logging |
| B11 | Accessibility (a11y) | 7/10 | 365 aria refs, 12 alt tags, keyboard nav partial | WCAG 2.1 AA audit, fix contrast, focus management |
| B12 | Internationalization | 3/10 | Locale in farm config, getLocale() used, no i18n framework | Add react-intl or i18next for multi-language |
| B13 | Code splitting | 8/10 | 15 lazy/Suspense refs, route-level code splitting | Verify chunks are reasonably sized |
| B14 | PWA / Offline | 6/10 | Service worker exists, manifest.json exists, basic cache | Add offline data queue, sync on reconnect |
| B15 | Design system | 7/10 | @lifeatlas/ui package, consistent component patterns | Document component API, add Storybook |

**Frontend Average: 6.1/10**

---

## C. SECURITY (15 metrics)

| # | Metric | Score | Evidence | Fix to 10 |
|---|---|---|---|---|
| C1 | Authentication | 8/10 | JWT via Supabase, middleware enforces on all routes, dev bypass documented | Add MFA support, session rotation |
| C2 | Authorization (RBAC) | 5/10 | farm_members table with roles, require_role on 3 routers only | Enforce require_role on ALL sensitive endpoints |
| C3 | Input sanitization | 7/10 | XSS validation on models (`must not contain script content`) | Add sanitization middleware globally |
| C4 | SQL injection | 10/10 | No raw SQL anywhere, all queries via Supabase client ORM | Maintain |
| C5 | Prompt injection | 4/10 | 6 f-string vectors where user content enters agent prompts | Add prompt sanitization layer before agent dispatch |
| C6 | CORS | 8/10 | Restricted to ALLOWED_ORIGINS env var, no wildcard | Verify production origins are locked down |
| C7 | Rate limiting | 7/10 | Applied to 14 endpoints, per-IP limits | Apply to all endpoints, add per-user limits |
| C8 | Secrets management | 9/10 | All via env vars, no hardcoded secrets found | Add secret rotation policy |
| C9 | Dependency vulnerabilities | 6/10 | pip-audit added to CI, not yet run on current deps | Run audit, fix critical/high vulns |
| C10 | HTTPS / TLS | 9/10 | Vercel enforces HTTPS, HSTS headers via middleware | Verify all external API calls use HTTPS |
| C11 | Security headers | 8/10 | SecurityHeadersMiddleware adds X-Frame, X-Content-Type, CSP | Add Permissions-Policy header |
| C12 | Pen test | 1/10 | No penetration test ever performed | Run OWASP ZAP or Burp Suite scan |
| C13 | Data encryption at rest | 7/10 | Supabase encrypts at rest, no client-side encryption | Add field-level encryption for PII |
| C14 | Audit trail | 6/10 | audit_log migration exists, not fully wired | Wire all mutations to audit_log table |
| C15 | Session management | 5/10 | Supabase handles sessions, no explicit timeout/revocation | Add session timeout, force logout on role change |

**Security Average: 6.7/10**

---

## D. AI / AGENTS (10 metrics)

| # | Metric | Score | Evidence | Fix to 10 |
|---|---|---|---|---|
| D1 | Agent architecture | 8/10 | 5 specialist agents, orchestrator, bus, intent routing | Add agent health monitoring, fallback chains |
| D2 | Hope orchestrator | 7/10 | Keyword-based intent routing, fan-out for multi-domain | Add LLM-based intent classification for ambiguous queries |
| D3 | Data grounding | 8/10 | All agents query Supabase directly, evidence-linked responses | Add confidence thresholds, source citations in responses |
| D4 | Prompt safety | 4/10 | No prompt sanitization, user content enters f-strings | Add NeMo Guardrails or custom sanitization layer |
| D5 | Model cost control | 7/10 | Hope uses deterministic routing (no LLM for intent), $1/day ZeroClaw cap | Add token counting, cost tracking per request |
| D6 | Agent testing | 5/10 | 2 test files for agents, 34 agent tests | Add integration tests with real Supabase data |
| D7 | ZeroClaw bridge | 6/10 | /ingest-and-ask endpoint coded, adapter models exist | Wire Telegram bot to endpoint, test full flow |
| D8 | Explainability | 7/10 | AgentResult includes evidence list, confidence score | Add reasoning chain, show which data informed the answer |
| D9 | Anomaly detection | 4/10 | anomaly_detector.py exists, not integrated to alerts | Wire to notifications, add threshold configuration |
| D10 | Sensor integration | 3/10 | Sensor model + WebSocket exist, no real sensor connected | Add MQTT broker, connect IoT gateway, ingest real data |

**AI Average: 5.9/10**

---

## E. DEVOPS / INFRA (10 metrics)

| # | Metric | Score | Evidence | Fix to 10 |
|---|---|---|---|---|
| E1 | CI pipeline | 6/10 | 1 GitHub Actions workflow (test + lint + audit) | Add integration tests, deploy gates, PR checks |
| E2 | CD pipeline | 5/10 | Manual `vercel deploy --prod`, no auto-deploy on merge | Wire Vercel to GitHub for auto-deploy on push |
| E3 | Staging environment | 2/10 | No staging, only prod | Create staging Vercel project with separate Supabase |
| E4 | Docker | 7/10 | Dockerfile exists, python 3.12-slim base | Add multi-stage build, health check in Docker |
| E5 | Monitoring | 2/10 | No Sentry, no APM, no uptime monitoring | Add Sentry + UptimeRobot + Vercel analytics |
| E6 | Backup strategy | 3/10 | Supabase daily backups (Pro plan feature) | Enable point-in-time recovery, test restore procedure |
| E7 | Infrastructure as code | 3/10 | No Terraform/Pulumi, manual Vercel/Supabase config | Add IaC for reproducible environments |
| E8 | Rollback procedure | 4/10 | Vercel has deployment history, no documented rollback | Document rollback procedure, add deploy tags |
| E9 | Log aggregation | 4/10 | structlog to stdout, Vercel captures logs | Add centralized logging (Axiom, Datadog, or Loki) |
| E10 | Load testing | 1/10 | No load test ever run | Run k6 or Locust with 1000 concurrent users |

**DevOps Average: 3.7/10**

---

## F. DATA / PRIVACY (10 metrics)

| # | Metric | Score | Evidence | Fix to 10 |
|---|---|---|---|---|
| F1 | Data model completeness | 8/10 | 105 schemas, covers horses/health/breeding/events/facilities | Add sensor data schema, weather integration |
| F2 | Migration management | 6/10 | 5 SQL migrations + 3 scripts, manual execution | Add migration runner to CI, add rollback scripts |
| F3 | RLS policies | 6/10 | RLS refs exist, farm_id isolation, some tables blocked (503) | Audit all RLS policies, fix vaccinations table |
| F4 | GDPR compliance | 7/10 | Data export + deletion endpoints live | Add privacy policy, consent management UI, DPA template |
| F5 | Data validation | 8/10 | Pydantic models on all endpoints, field validators | Add business rule validation (date ranges, cross-field) |
| F6 | Backup & recovery | 3/10 | Supabase manages, no tested restore procedure | Test restore, document RTO/RPO |
| F7 | Data sovereignty | 8/10 | Edge-native architecture, Supabase in EU region possible | Document data residency, add region selector |
| F8 | Consent management | 6/10 | consent router exists, grant/revoke per horse | Add consent UI in frontend, audit consent compliance |
| F9 | Data quality | 5/10 | No data validation scripts, no duplicate detection | Add data quality checks, dedup on insert |
| F10 | Analytics / reporting | 6/10 | 6 report endpoints (farm summary, breeding, health, financial, passport, foals) | Add custom report builder, export to PDF |

**Data Average: 6.3/10**

---

## G. UX / MOBILE (10 metrics)

| # | Metric | Score | Evidence | Fix to 10 |
|---|---|---|---|---|
| G1 | Responsive design | 7/10 | 169 responsive breakpoint refs in components | Test on iPhone SE (375px), fix overflow issues |
| G2 | Touch targets | 6/10 | Buttons exist, not all meet 44px minimum | Audit all interactive elements for 44px minimum |
| G3 | Offline support | 5/10 | Service worker caches app shell, no data offline queue | Add offline data queue with sync-on-reconnect |
| G4 | Camera integration | 6/10 | PhotoCapture component uploads to Supabase storage | Test on mobile browsers, add compression |
| G5 | Navigation | 7/10 | Tab bar, ScrollToTop, route-level code splitting | Add breadcrumbs, back navigation, swipe gestures |
| G6 | Performance (LCP) | 5/10 | No performance metrics, no Lighthouse audit | Run Lighthouse, target LCP < 2.5s, FID < 100ms |
| G7 | Onboarding flow | 4/10 | Signup page exists (Supabase auth), no farm setup wizard | Build farm creation wizard, invite team flow |
| G8 | Notification UX | 4/10 | Backend notifications exist, no push to device | Add FCM for mobile push, in-app notification center |
| G9 | Search & filter | 5/10 | Horse status filter on dashboard, no global search | Add search across horses/events/health records |
| G10 | Dark mode | 8/10 | Full dark mode via CSS variables, .dark class | Verify contrast ratios in dark mode |

**UX Average: 5.7/10**

---

## H. BUSINESS / REVENUE (10 metrics)

| # | Metric | Score | Evidence | Fix to 10 |
|---|---|---|---|---|
| H1 | Billing integration | 6/10 | Stripe checkout + webhook + portal endpoints exist | Test full flow in sandbox, add subscription tiers |
| H2 | User onboarding | 3/10 | Signup exists, no guided setup, no farm creation | Build 3-step wizard: create account → create farm → invite team |
| H3 | Demo mode | 8/10 | Demo banner shows when API offline, mock data fallback | Add "Request Demo" CTA, guided product tour |
| H4 | Multi-tenancy | 7/10 | farm_id isolation, farm_members table, config-driven | Add farm switching UI, multi-farm dashboard |
| H5 | API monetization | 4/10 | MCP keys endpoint exists, no API billing | Add usage metering, tiered API access, developer portal |
| H6 | Customer support | 2/10 | No support channel, no help docs, no FAQ | Add Intercom/Crisp, help center, knowledge base |
| H7 | Analytics tracking | 4/10 | PostHog env vars in frontend, not wired | Wire PostHog, add event tracking, funnel analysis |
| H8 | Marketplace | 3/10 | MarketplacePage.tsx exists, placeholder content | Build horse marketplace with real listings |
| H9 | Partner API | 5/10 | Full REST API with auth, no partner docs | Create developer docs, API key management UI |
| H10 | Regulatory compliance | 4/10 | AHA forms exist, WAHO mentioned, no certifications | Get AHA integration approval, SA stud book partnership |

**Business Average: 4.6/10**

---

## OVERALL SCORECARD

| Category | Score | Weight | Weighted |
|---|---|---|---|
| A. Backend | 6.5/10 | 20% | 1.30 |
| B. Frontend | 6.1/10 | 15% | 0.92 |
| C. Security | 6.7/10 | 15% | 1.01 |
| D. AI/Agents | 5.9/10 | 10% | 0.59 |
| E. DevOps | 3.7/10 | 10% | 0.37 |
| F. Data/Privacy | 6.3/10 | 10% | 0.63 |
| G. UX/Mobile | 5.7/10 | 10% | 0.57 |
| H. Business | 4.6/10 | 10% | 0.46 |
| **TOTAL** | | **100%** | **5.85/10** |

---

## VERDICT: 5.85/10 — NOT PRODUCTION READY

### What's strong (7+):
- SQL injection protection (10/10)
- API endpoint coverage (9/10)
- Secrets management (9/10)
- Health check (9/10)
- Authentication (8/10)
- Type safety (8/10)
- Data grounding in AI (8/10)
- Demo mode (8/10)

### What's killing us (< 4):
- Load testing (1/10) — never tested
- Pen test (1/10) — never tested
- Monitoring (2/10) — no Sentry, no APM
- Staging environment (2/10) — only prod exists
- Customer support (2/10) — no help channel
- User onboarding (3/10) — no farm setup wizard
- Caching (3/10) — no cache layer
- Infrastructure as code (3/10) — manual config
- Bundle size (3/10) — build broken, mock data in bundle
- i18n (3/10) — no multi-language
- Marketplace (3/10) — placeholder
- Sensor integration (3/10) — no real sensors connected

---

## ROADMAP TO PRODUCTION (Priority Order)

### Week 1: "Dean can use it" (5.85 → 7.0)
| Day | Task | Metrics affected |
|---|---|---|
| Mon | Fix Tailwind build error, deploy clean FE | B6 (3→7) |
| Mon | Fix vaccinations 503 (RLS policy) | A10 (6→7) |
| Mon | Wire Vercel auto-deploy on GitHub push | E2 (5→8) |
| Tue | Build farm creation wizard (3 steps) | H2 (3→7), G7 (4→7) |
| Tue | Add Sentry to BE + FE | E5 (2→7), B8 (7→8) |
| Wed | RBAC enforcement on all sensitive endpoints | C2 (5→8) |
| Wed | Add prompt sanitization to agent layer | C5 (4→7), D4 (4→7) |
| Thu | Mobile testing + touch target fixes | G1 (7→8), G2 (6→8) |
| Thu | Remove console.log, strip mock data from bundle | B10 (6→9), B4 (5→7) |
| Fri | Run OWASP ZAP basic scan | C12 (1→5) |
| Fri | Run k6 load test (100 users) | E10 (1→5) |

### Week 2: "Investor-ready" (7.0 → 8.0)
| Task | Metrics |
|---|---|
| Create staging environment | E3 (2→7) |
| Add PostHog analytics | H7 (4→8) |
| Build notification center + FCM push | G8 (4→7) |
| Add Intercom/Crisp chat | H6 (2→6) |
| Test Stripe billing flow end-to-end | H1 (6→8) |
| Wire anomaly detection to alerts | D9 (4→7) |
| Add audit trail to all mutations | C14 (6→8) |
| k6 stress test at 1000 users | E10 (5→8) |

### Week 3: "Enterprise-grade" (8.0 → 9.0)
| Task | Metrics |
|---|---|
| Full pen test (Burp Suite or external firm) | C12 (5→8) |
| Add Redis caching layer | A19 (3→7) |
| MQTT sensor integration (real IoT data) | D10 (3→7) |
| Add background job queue (ARQ) | A20 (4→7) |
| API developer portal + docs | H9 (5→8) |
| Centralized logging (Axiom) | E9 (4→8) |
| Infrastructure as code (Pulumi) | E7 (3→7) |

### Week 4: "Scale" (9.0 → 9.5+)
| Task | Metrics |
|---|---|
| Multi-language (i18n) | B12 (3→7) |
| Horse marketplace MVP | H8 (3→7) |
| API monetization + usage metering | H5 (4→7) |
| Offline data queue + sync | G3 (5→8) |
| Custom report builder | F10 (6→8) |
| Session management hardening | C15 (5→8) |

---

## Dean's Team Specific Asks

| Ask | Status | What's needed |
|---|---|---|
| Mobile phones | 6/10 | Fix build, test on real devices, touch targets |
| Buy sensors | 3/10 | Need MQTT broker + IoT gateway + sensor schema |
| Live weather data | 2/10 | Integrate weather API (OpenWeatherMap), correlate with health |
| Run analytics | 6/10 | 6 report endpoints live, need custom report builder |
| Hire AI experts for API | 5/10 | API exists, needs developer docs + API key management |
| Role-based views | 5/10 | RBAC code exists, enforcement partial, FE doesn't filter by role |

---

*Generated by GLASS + PRISM — Hostile VC DD Module, 2026-04-18*
