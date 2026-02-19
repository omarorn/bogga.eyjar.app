#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/create-roadmap-issues.sh
#   REPO=omarorn/bogga.eyjar.app scripts/create-roadmap-issues.sh

REPO="${REPO:-omarorn/bogga.eyjar.app}"

ensure_label() {
  local name="$1"
  local color="$2"
  local desc="$3"
  gh label create "$name" --repo "$REPO" --color "$color" --description "$desc" --force >/dev/null
}

create_issue() {
  local title="$1"
  local labels="$2"
  local body_file="$3"
  gh issue create --repo "$REPO" --title "$title" --label "$labels" --body "$(cat "$body_file")"
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# Core labels
ensure_label "feature" "1D76DB" "New product capability"
ensure_label "frontend" "A475F9" "UI and client-side changes"
ensure_label "backend" "0E8A16" "API and server-side logic"
ensure_label "ux" "FBCA04" "User experience improvements"
ensure_label "notifications" "5319E7" "Push or in-app notifications"
ensure_label "pwa" "0052CC" "Progressive Web App behavior"
ensure_label "database" "B60205" "Schema, queries, or migrations"
ensure_label "performance" "C2E0C6" "Performance-focused work"
ensure_label "safety" "D93F0B" "Data safety and recovery"
ensure_label "auth" "C5DEF5" "Authentication/authorization"
ensure_label "onboarding" "F9D0C4" "First-run and activation UX"
ensure_label "priority: p1" "B60205" "Highest near-term priority"
ensure_label "priority: p2" "D93F0B" "Medium priority"
ensure_label "priority: p3" "FBCA04" "Lower priority"

cat > "$tmpdir/1.md" <<'MD'
## Why
Notendur sjá strax hvað þarf að klára núna.

## Scope
- Bæta við dagsetningarsíum í UI (`Í dag`, `Á morgun`, `Seint`)
- Uppfæra API/query logic fyrir due-date flokka

## Acceptance Criteria
- Notandi getur skipt milli 3 flipa
- Verkefni birtast í réttum flokki miðað við local date/time
- Overdue verkefni sjást alltaf í `Seint`

## Tasks
- [ ] Skilgreina dagsetningareglur (timezone-safe)
- [ ] Implementa síuflipa í UI
- [ ] Bæta við API-síu/röðun
- [ ] Skrifa unit/integration tests

## Milestone
Milestone A (2 vikur)
MD

cat > "$tmpdir/2.md" <<'MD'
## Why
Minnkar gleymd verkefni.

## Scope
- Reminder settings per task
- Trigger 24h + 2h fyrir deadline

## Acceptance Criteria
- Notandi getur kveikt/slökkt á reminders
- Reminder berst á réttum tíma (innan ásættanlegra marka)

## Tasks
- [ ] Permission flow fyrir notifications
- [ ] Gagnamódel fyrir reminder preferences
- [ ] Scheduling/dispatch logic
- [ ] E2E test fyrir create->notify path

## Depends on
- Day View Filters

## Milestone
Milestone A (2 vikur)
MD

cat > "$tmpdir/3.md" <<'MD'
## Why
Sparar tíma í síendurteknum verkum.

## Scope
- daily/weekly/monthly recurrence rules

## Acceptance Criteria
- Kláruð recurring task býr til næsta instance sjálfvirkt
- No duplicate generation

## Tasks
- [ ] D1 schema breyting fyrir recurrence fields
- [ ] API validation + generation logic
- [ ] UI controls fyrir recurrence
- [ ] Integration tests fyrir edge-cases

## Depends on
- Day View Filters

## Milestone
Milestone A (2 vikur)
MD

cat > "$tmpdir/4.md" <<'MD'
## Why
Hraðari innsetning, færri smelli.

## Scope
Parse-a `#tag`, `@time`, `!priority` úr einni línu.

## Acceptance Criteria
- Input eins og `Kaupa mjólk #innkaup @20:00 !hátt` parse-ast rétt
- Villa í syntax stoppar ekki task creation (graceful fallback)

## Tasks
- [ ] Parser spec + test-cases
- [ ] UI quick-add field
- [ ] Mapping í núverandi create-task API
- [ ] Unit tests fyrir parser

## Milestone
Milestone B (vikur 3-6)
MD

cat > "$tmpdir/5.md" <<'MD'
## Why
Auðveldara að finna verkefni í stærri listum.

## Scope
Leit í title/tag + status/date filters.

## Acceptance Criteria
- Leitarsvörun <200ms við venjulegt álag
- Síur má sameina án rangrar niðurstöðu

## Tasks
- [ ] API query parameters fyrir leit/síur
- [ ] UI search + filter controls
- [ ] Index review í D1 ef þarf
- [ ] Performance benchmark script

## Depends on
- Day View Filters

## Milestone
Milestone B (vikur 3-6)
MD

cat > "$tmpdir/6.md" <<'MD'
## Why
Ver gegn mistökum.

## Scope
Soft-delete + restore innan 30 daga.

## Acceptance Criteria
- Eytt task/list fer í ruslafötu
- Restore skilar réttu state
- Hard delete eftir retention policy

## Tasks
- [ ] Schema updates fyrir soft-delete metadata
- [ ] Trash endpoints (list/restore/purge)
- [ ] UI fyrir ruslafötu
- [ ] Tests fyrir restore og permission checks

## Milestone
Milestone B (vikur 3-6)
MD

cat > "$tmpdir/7.md" <<'MD'
## Why
Deiling með raunverulegri samvinnu.

## Scope
`owner`, `editor`, `viewer` hlutverk.

## Acceptance Criteria
- Viewer getur ekki breytt efni
- Editor getur uppfært verkefni en ekki eigandastillingar
- Owner getur stjórnað aðgangi

## Tasks
- [ ] Access model + DB tables fyrir membership
- [ ] Authorization middleware á öllum list/task endpoints
- [ ] Invite/manage collaborators UI
- [ ] Security regression tests

## Depends on
- Day View Filters
- Search & Filters

## Milestone
Milestone C (vikur 7-10)
MD

cat > "$tmpdir/8.md" <<'MD'
## Why
Fljótari gangsetning fyrir nýja notendur.

## Scope
5-8 tilbúin templates (innkaup, ferðalag, vikuskipulag...).

## Acceptance Criteria
- Notandi getur stofnað lista úr template með einum smelli
- Template býr til rétt default tasks/tags

## Tasks
- [ ] JSON source fyrir templates
- [ ] Template picker UI
- [ ] API support fyrir create-from-template
- [ ] Onboarding tracking metric

## Depends on
- Day View Filters

## Milestone
Milestone C (vikur 7-10)
MD

create_issue "Day View Filters (Í dag / Á morgun / Seint)" "feature,frontend,backend,ux,priority: p1" "$tmpdir/1.md"
create_issue "Deadline Reminders" "feature,notifications,backend,pwa,priority: p1" "$tmpdir/2.md"
create_issue "Recurring Tasks" "feature,backend,frontend,database,priority: p1" "$tmpdir/3.md"
create_issue "Quick Add Syntax" "feature,frontend,ux,priority: p2" "$tmpdir/4.md"
create_issue "Search & Filters" "feature,frontend,backend,performance,priority: p2" "$tmpdir/5.md"
create_issue "Undo + Trash Bin" "feature,backend,frontend,safety,priority: p2" "$tmpdir/6.md"
create_issue "Shared Lists with Roles" "feature,auth,backend,frontend,priority: p3" "$tmpdir/7.md"
create_issue "List Templates" "feature,frontend,onboarding,priority: p3" "$tmpdir/8.md"

echo "Done. Created roadmap issues in $REPO"
