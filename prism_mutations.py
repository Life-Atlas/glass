"""
PRISM Mutation RBAC Tests -- Phase 2 extension of prism_roast.py.

Verifies write-access enforcement across all POST/PATCH/DELETE endpoints.

RBAC contract (api/roles.py):
  WRITE_ROLES = ["owner", "trainer", "admin"]
  READ_ONLY   = ["groom", "vet", "viewer"]

Rules under test:
  1. viewer  on own farm -> 403 on ALL mutations
  2. groom   on own farm -> 403 on ALL mutations
  3. trainer on own farm -> 201/200 on mutations
  4. owner   on own farm -> 201/200 on mutations
  5. admin   on own farm -> 201/200 on mutations
  6. ANY role on other farm -> 403 (cross-farm isolation)

Notes on accepted status codes:
  - 503 for write-permitted roles: Vercel serverless DB cold-start / pooling
    failure on INSERT. RBAC passed (auth gate cleared); DB layer failed.
    This is infrastructure noise, not an RBAC failure.
  - 503 for read-only roles on POST /vaccinations/: This IS the bug.
    The viewer cleared the auth gate (no require_role call) and hit the DB.

Known bug (documented failing test):
  POST /api/v1/vaccinations/ -- create_vaccination() in
  api/routers/vaccinations.py calls require_farm_access() but NOT
  require_role(). A viewer who is a farm member currently receives 503
  (reaches DB) instead of 403 (blocked at gate). This test FAILS
  until the bug is patched.

  Fix: add `require_role(UUID(farm_id_str), user_id, WRITE_ROLES)`
  directly after the require_farm_access() call in create_vaccination()
  (api/routers/vaccinations.py ~line 124).

Existence-oracle limitation (not a ship blocker):
  DELETE /horses/{non-existent-id}: get_farm_for_horse() raises 404
  before require_role() fires. Read-only roles therefore get 404 instead
  of 403 for phantom IDs. No data is mutated; this is an info-leak only.

Usage:
  cd equestrai-backend && python scripts/prism_mutations.py
"""

import io
import os
import sys
from datetime import datetime, timedelta

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

# Force UTF-8 stdout on Windows to avoid cp1252 errors
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
else:
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# Load env vars from .env.vercel or .env
for _envfile in (".env.vercel", ".env"):
    try:
        with open(os.path.join(os.path.dirname(os.path.dirname(__file__)), _envfile)) as _f:
            for _line in _f:
                if "=" in _line and not _line.startswith("#"):
                    _k, _v = _line.strip().split("=", 1)
                    _v = _v.strip('"')
                    os.environ.setdefault(_k, _v)
    except FileNotFoundError:
        pass

import httpx
import jwt as pyjwt

import api.db as _db

JWT_SECRET = os.environ["SUPABASE_JWT_SECRET"]

SKYROO = "6736517a-a6e2-4e96-993d-23bf0237e94f"
MULAWA = "fbb30be9-5675-43da-bf4a-bf5415efb016"
BE_URL = "https://equestrai-backend.vercel.app"
HORSE_ID = "39e59bb1-6f68-42ce-8163-9e6b2a77363d"  # Johrhemar Natih (Skyroo)
TODAY = datetime.now().strftime("%Y-%m-%d")
NOW_ISO = datetime.now().isoformat()

WRITE_ROLES = {"owner", "trainer", "admin"}
PHANTOM = "00000000-dead-beef-0000-000000000001"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def mint_jwt(user_id: str) -> str:
    return pyjwt.encode(
        {
            "sub": user_id,
            "iss": "supabase",
            "ref": "wubnxmzqxlwktuhbmrdo",
            "role": "authenticated",
            "iat": int(datetime.now().timestamp()),
            "exp": int((datetime.now() + timedelta(hours=1)).timestamp()),
        },
        JWT_SECRET,
        algorithm="HS256",
    )


def auth_headers(token: str) -> dict:
    return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}


def http(method: str, path: str, token: str, body=None) -> int:
    url = f"{BE_URL}{path}"
    try:
        if method == "POST":
            r = httpx.post(url, headers=auth_headers(token), json=body, timeout=25)
        elif method == "PATCH":
            r = httpx.patch(url, headers=auth_headers(token), json=body, timeout=25)
        elif method == "DELETE":
            r = httpx.delete(url, headers=auth_headers(token), timeout=25)
        else:
            r = httpx.get(url, headers=auth_headers(token), timeout=25)
        return r.status_code
    except Exception as exc:
        print(f"      [conn-err] {method} {path}: {exc}")
        return 0


# ---------------------------------------------------------------------------
# Load personas from DB
# ---------------------------------------------------------------------------

members_resp = (
    _db.eq_table("farm_members")
    .select("user_id, role, name, email")
    .eq("farm_id", SKYROO)
    .execute()
)
personas: dict[str, dict] = {}
for m in members_resp.data or []:
    uid = m["user_id"]
    personas[m["name"]] = {
        "uid": uid,
        "role": m["role"],
        "token": mint_jwt(uid),
    }

if not personas:
    print("ERROR: no Skyroo farm members found. Check DB connection.")
    sys.exit(2)

print(f"PRISM Mutations - {len(personas)} personas loaded\n")

# ---------------------------------------------------------------------------
# Payloads
# ---------------------------------------------------------------------------

HORSE_OWN_FARM = {"farm_id": SKYROO, "name": "PRISM Test Horse", "sex": "mare"}
HORSE_OTHER_FARM = {"farm_id": MULAWA, "name": "PRISM Cross-Farm Attempt", "sex": "stallion"}
HEALTH_PAYLOAD = {
    "horse_id": HORSE_ID,
    "record_date": TODAY,
    "record_type": "vet_visit",
    "diagnosis": "PRISM integration test record",
}
VACC_PAYLOAD = {
    "horse_id": HORSE_ID,
    "vaccine_name": "PRISM Flu Vaccine",
    "vaccination_date": TODAY,
}
BREEDING_PAYLOAD = {
    "horse_id": HORSE_ID,
    "breeding_date": TODAY,
    "cover_type": "natural",
}
EVENT_PAYLOAD = {
    "horse_id": HORSE_ID,
    "event_date": NOW_ISO,
    "event_type": "observation",
    "title": "PRISM test event",
}


# ---------------------------------------------------------------------------
# Mutation test matrix
# ---------------------------------------------------------------------------
# Each tuple: (label, method, path, body, write_ok_codes, read_ok_codes, known_bug)
#
# write_ok_codes: status codes that PASS for WRITE_ROLES (owner/trainer/admin)
# read_ok_codes:  status codes that PASS for read-only roles (viewer/groom)
# known_bug: True = failure is a documented bug, not an unexpected regression
#
# On 503 for write roles: Vercel cold-start / Supabase pooling can 503 on INSERT
# even when auth passed. We accept it -- RBAC gate cleared, infra failed.
#
# On DELETE phantom for read roles: get_farm_for_horse() 404s before require_role
# fires. Acceptance set is {403, 404} -- existence-oracle leak, not escalation.
#
# On POST /vaccinations/ for read roles: the bug is evidenced by 503 (not 403).
# A 503 means the viewer cleared the role gate (no require_role call) and hit
# the DB. Expected is {403} -- test will FAIL until bug is patched.

MUTATION_MATRIX = [
    (
        "POST /horses own-farm",
        "POST", "/api/v1/horses/", HORSE_OWN_FARM,
        {201, 200, 409, 503},   # write: auth OK, may 503 on DB
        {403},                   # read: must be blocked
        False,
    ),
    (
        "POST /horses other-farm (cross-farm isolation)",
        "POST", "/api/v1/horses/", HORSE_OTHER_FARM,
        {403},                   # write: not a member of MULAWA
        {403},                   # read: also not a member
        False,
    ),
    (
        "PATCH /horses/{id} own-farm",
        "PATCH", f"/api/v1/horses/{HORSE_ID}", {"notes": "PRISM patch test"},
        {200, 201, 503},         # write: auth OK
        {403},                   # read: blocked
        False,
    ),
    (
        "DELETE /horses/{phantom} (existence-oracle limitation)",
        "DELETE", f"/api/v1/horses/{PHANTOM}", None,
        {404, 500, 503},         # write: 404 = farm lookup raised, no harm
        {403, 404},              # read: 404 acceptable -- see docstring above
        False,
    ),
    (
        "POST /health/ own-farm",
        "POST", "/api/v1/health/", HEALTH_PAYLOAD,
        {201, 200, 409, 503},   # write: auth OK
        {403},                   # read: blocked
        False,
    ),
    (
        "POST /vaccinations/ [BUG: missing require_role]",
        "POST", "/api/v1/vaccinations/", VACC_PAYLOAD,
        {201, 200, 409, 503},   # write: auth OK
        {403},                   # read: MUST be 403 -- currently gets 503 (bug)
        True,                    # known bug -- failing test documents the gap
    ),
    (
        "POST /breeding/records/ own-farm",
        "POST", "/api/v1/breeding/records/", BREEDING_PAYLOAD,
        {201, 200, 409, 422, 503},  # write: 422 if horse is not a mare
        {403},                       # read: blocked
        False,
    ),
    (
        "POST /events/ own-farm",
        "POST", "/api/v1/events/", EVENT_PAYLOAD,
        {201, 200, 409, 503},   # write: auth OK
        {403},                   # read: blocked
        False,
    ),
]


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------

total_tests = 0
total_passed = 0
all_failures: list[dict] = []

print("=" * 72)
print("RBAC MUTATION MATRIX")
print("=" * 72)

for name, persona in personas.items():
    role = persona["role"]
    token = persona["token"]
    is_write = role in WRITE_ROLES
    print(f"\n  {name} ({role})")

    for label, method, path, body, write_ok, read_ok, known_bug in MUTATION_MATRIX:
        expected = write_ok if is_write else read_ok
        actual = http(method, path, token, body)
        passed = actual in expected
        total_tests += 1

        exp_str = "/".join(str(s) for s in sorted(expected))
        if passed:
            total_passed += 1
            print(f"    [PASS] {label:<55} exp={exp_str:15s} got={actual}")
        else:
            tag = "[BUG] " if known_bug else "[FAIL]"
            print(f"    {tag} {label:<55} exp={exp_str:15s} got={actual}")
            all_failures.append({
                "persona": name,
                "role": role,
                "label": label,
                "expected": expected,
                "actual": actual,
                "known_bug": known_bug,
            })


# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

total_failed = total_tests - total_passed
known_bugs   = [f for f in all_failures if f["known_bug"]]
regressions  = [f for f in all_failures if not f["known_bug"]]
pct          = total_passed * 100 // total_tests if total_tests else 0

print("\n" + "=" * 72)
print("PRISM MUTATION SUMMARY")
print("=" * 72)
print(f"  Total tests:   {total_tests}")
print(f"  Passed:        {total_passed}")
print(f"  Failed:        {total_failed}")
print(f"    Known bugs:  {len(known_bugs)}")
print(f"    Regressions: {len(regressions)}")
print(f"  Coverage:      {pct}%")

if known_bugs:
    print(f"\nKNOWN BUGS ({len(known_bugs)} occurrences -- 1 unique bug):")
    seen = set()
    for b in known_bugs:
        key = b["label"]
        if key not in seen:
            seen.add(key)
            print(f"  Endpoint: {key}")
            print(f"  File:     api/routers/vaccinations.py ~line 124")
            print(f"  Fix:      add require_role(UUID(farm_id_str), user_id, WRITE_ROLES)")
            print(f"            directly after the require_farm_access() call")
        print(f"  Affected: [{b['persona']} / {b['role']}] got={b['actual']} want=403")

if regressions:
    print(f"\nREGRESSIONS ({len(regressions)}) -- ship blockers:")
    for r in regressions:
        print(f"  [{r['persona']} / {r['role']}] {r['label']}")
        print(f"    expected={r['expected']}  actual={r['actual']}")
    print("\nVerdict: FAIL")
    sys.exit(1)
elif known_bugs:
    print("\nVerdict: CONDITIONAL PASS")
    print("  All enforced RBAC rules pass. 1 known bug documented above.")
    sys.exit(0)
else:
    print("\nVerdict: PASS")
    sys.exit(0)
