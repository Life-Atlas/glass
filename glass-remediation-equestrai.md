# EquestRai — Production Remediation Plan
**Target:** Move from GLASS 2.0/10 (demo) to GLASS 7.0/10 (production)
**Date written:** 2026-04-20
**Current blocker:** Production Reality gate fails all 4 questions

Each step below answers one or more of the four Production Reality questions.
Steps are ordered by dependency — do them in sequence.

---

## Step 1 — Remove DEV_BYPASS_AUTH from production path

**Answers:** Q2 (real database) + Q3 (real auth works)
**Effort:** 30 minutes
**Risk:** Medium — existing dev workflow breaks if not isolated to .env.local

### What to do

In the EquestRai frontend (`C:/Users/ceo/lifeatlas-core-test2/apps/lifeatlas-equestrai`):

1. Find every reference to `DEV_BYPASS_AUTH`:
   ```bash
   grep -rn "DEV_BYPASS_AUTH" src/ --include="*.ts" --include="*.tsx"
   ```

2. The pattern should only exist in `.env.local` (dev) and never in `.env.production`. Verify:
   ```bash
   cat .env.production | grep BYPASS   # should return nothing
   cat .env.local | grep BYPASS        # acceptable here only
   ```

3. In any component or hook that reads `DEV_BYPASS_AUTH`, wrap the check to ensure it only activates when `import.meta.env.MODE === 'development'`:
   ```typescript
   const bypassAuth = import.meta.env.DEV && import.meta.env.VITE_DEV_BYPASS_AUTH === 'true';
   ```

4. Verify the production build does not include bypass:
   ```bash
   pnpm build
   grep -r "DEV_BYPASS_AUTH\|bypass" dist/
   ```

In the EquestRai backend (`C:/Users/ceo/equestrai-backend`):

1. Confirm no bypass in production config:
   ```bash
   grep -rn "DEV_BYPASS_AUTH\|bypass_auth" api/ --include="*.py" | grep -v test | grep -v "#"
   ```

2. Any auth bypass must be wrapped in `if settings.environment == "development":`

---

## Step 2 — Wire VITE_API_URL to the deployed backend

**Answers:** Q1 (publicly deployed) + Q2 (real database)
**Effort:** 15 minutes
**Risk:** Low

### What to do

1. Confirm the backend is already deployed at `https://equestrai-backend.vercel.app` (health 200 OK confirmed in prior audits).

2. In the frontend `.env.production`:
   ```
   VITE_API_URL=https://equestrai-backend.vercel.app
   ```

3. Verify no fallback to localhost:
   ```bash
   grep -rn "localhost\|127\.0\.0" src/ --include="*.ts" --include="*.tsx" | grep -v "// \|#"
   ```

4. Deploy the frontend to a public URL (Vercel recommended):
   ```bash
   vercel --prod
   ```
   Record the output URL. This is the answer to Q1.

---

## Step 3 — Enable real Supabase auth

**Answers:** Q3 (real auth works)
**Effort:** 1–2 hours
**Risk:** Medium — requires Supabase project to have equestrai schema and at least one user seeded

### What to do

1. Confirm Supabase project has the equestrai schema tables:
   ```bash
   # Run against Supabase SQL editor or psql
   SELECT table_name FROM information_schema.tables
   WHERE table_schema = 'equestrai';
   ```
   Expected tables: `horses`, `farms`, `events`, `vaccinations`, `facility_assignments`, `breeding_records`

2. Create a test user in Supabase Auth dashboard:
   - Email: `dean-test@skyroo.au` (or similar)
   - Password: a real password (not bypass)
   - Role: `manager`
   - Linked `farm_id`: the UUID of the Skyroo farm row in `equestrai.farms`

3. In the frontend, open the login page at the deployed URL and sign in with the test user credentials. Confirm:
   - JWT is issued
   - User is redirected to the dashboard
   - Dashboard attempts to call `/api/v1/horses/?farm_id={uuid}` with the JWT in the Authorization header

4. In the backend, confirm the horses endpoint reads from Supabase (not a local file) and returns data for the farm:
   ```bash
   curl -s -X GET "https://equestrai-backend.vercel.app/api/v1/horses/?farm_id={real-uuid}" \
     -H "Authorization: Bearer {real-jwt}"
   ```
   Expected: JSON array of horse objects. If empty, proceed to Step 4.

---

## Step 4 — Verify the 14 Skyroo horses are readable via the API

**Answers:** Q2 (real database) — confirms data is actually there
**Effort:** 30 minutes
**Risk:** Low

### What to do

1. Confirm the 14 horses are seeded in `equestrai.horses` for the Skyroo farm:
   ```sql
   SELECT id, name, breed, farm_id FROM equestrai.horses
   WHERE farm_id = '{skyroo-farm-uuid}'
   ORDER BY name;
   ```
   Expected: 14 rows matching the horses in `C:/Users/ceo/lifeatlas-core-test2/apps/lifeatlas-equestrai/src/data/skyroo-horses.ts`

2. If not seeded, run the migration or seed script. The horse data is already in the frontend data file — write a one-time seed:
   ```python
   # seed_skyroo_horses.py — run once against Supabase
   from supabase import create_client
   import os, json

   client = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_KEY"])
   horses = [...]  # paste from skyroo-horses.ts, converted to dicts
   client.table("equestrai.horses").insert(horses).execute()
   ```

3. After seeding, re-run the curl command from Step 3 and confirm 14 horses are returned.

4. In the frontend dashboard, after real login, confirm the horse cards show actual horse names (not "Mock Horse 1" or similar).

---

## Step 5 — Test one complete real user login end-to-end

**Answers:** Q4 (real users exist) — this is the final gate
**Effort:** 30 minutes (if Steps 1–4 are complete)
**Risk:** Low

### What to do

1. Open the deployed frontend URL in an incognito browser window (to rule out any dev session state).

2. Sign in with the test user credentials from Step 3.

3. Confirm the following flow works completely:
   - Login page → JWT issued → redirect to dashboard
   - Dashboard shows the 14 Skyroo horses (from Supabase, not mock data)
   - Clicking a horse opens the horse profile (calls `/api/v1/horses/{id}`)
   - Typing a message to Hope calls `/api/v1/hope/ask` with the real JWT and receives a response
   - No console errors about bypass flags, mock data, or localhost URLs

4. Screenshot the dashboard showing real horse data. This is the production evidence.

5. Record in the next GLASS audit:
   ```bash
   bash glass-audit.sh \
     --frontend C:/Users/ceo/lifeatlas-core-test2/apps/lifeatlas-equestrai \
     --backend C:/Users/ceo/equestrai-backend \
     --url https://equestrai-backend.vercel.app \
     --prod-deployed yes \
     --prod-real-db yes \
     --prod-real-auth yes \
     --prod-real-users yes
   ```

   Expected score after all steps complete: **65–75/100** (Production Reality gate open, remaining gaps in GDPR, mobile testing, load testing, WhatsApp integration).

---

## Expected Score Progression

| After Step | Production Reality | Estimated Score |
|---|---|---|
| Now (no steps done) | 4 NOs | 20/100 |
| After Step 1 (bypass removed) | 3 NOs | 20/100 (cap unchanged until deployed) |
| After Step 2 (frontend deployed) | 2 NOs | 20/100 (still no real auth) |
| After Step 3 (real auth works) | 1 NO | 40/100 (cap lifts partially) |
| After Step 4 (real data verified) | 1 NO | 40/100 |
| After Step 5 (real user login) | 0 NOs | **65–75/100** (code quality score applies) |

---

## Definition of Done

EquestRai exits "demo" status when ALL of the following are true simultaneously:

- [ ] Frontend is deployed to a public Vercel URL (not localhost)
- [ ] `DEV_BYPASS_AUTH` is absent from the production build
- [ ] `VITE_API_URL` points to `https://equestrai-backend.vercel.app` in production
- [ ] 14 Skyroo horses are confirmed present in `equestrai.horses` via authenticated API call
- [ ] One real user (Dean, Isaac, or Greg) has logged in and seen their horses
- [ ] GLASS audit run with all four `--prod-*` flags set to `yes` returns score > 40/100

Until all six boxes are checked, EquestRai is a demo. GLASS will score it 20/100.
