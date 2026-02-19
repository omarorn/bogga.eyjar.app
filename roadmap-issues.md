# Bogga Roadmap - GitHub Issue Drafts

Notkun: Búðu til eitt GitHub issue fyrir hvern kafla hér að neðan. Settu `Priority` og `Labels` eins og lagt er til.

## 1) Day View Filters (`Í dag`, `Á morgun`, `Seint`)
- Priority: P1
- Labels: `feature`, `frontend`, `backend`, `ux`
- Why: Notendur sjá strax hvað þarf að klára núna.
- Scope:
  - Bæta við dagsetningarsíum í UI.
  - Uppfæra API/query logic fyrir due-date flokka.
- Acceptance Criteria:
  - Notandi getur skipt milli 3 flipa.
  - Verkefni birtast í réttum flokki miðað við local date/time.
  - Overdue verkefni sjást alltaf í `Seint`.
- Tasks:
  - [ ] Skilgreina dagsetningareglur (timezone-safe).
  - [ ] Implementa síuflipa í UI.
  - [ ] Bæta við API-síu/röðun.
  - [ ] Skrifa unit/integration tests.

## 2) Deadline Reminders
- Priority: P1
- Labels: `feature`, `notifications`, `backend`, `pwa`
- Why: Minnkar gleymd verkefni.
- Scope:
  - Reminder settings per task.
  - Trigger 24h + 2h fyrir deadline.
- Acceptance Criteria:
  - Notandi getur kveikt/slökkt á reminders.
  - Reminder berst á réttum tíma (innan ásættanlegra marka).
- Tasks:
  - [ ] Permission flow fyrir notifications.
  - [ ] Gagnamódel fyrir reminder preferences.
  - [ ] Scheduling/dispatch logic.
  - [ ] E2E test fyrir create->notify path.
- Depends on: #1

## 3) Recurring Tasks
- Priority: P1
- Labels: `feature`, `backend`, `frontend`, `database`
- Why: Sparar tíma í síendurteknum verkum.
- Scope: daily/weekly/monthly recurrence rules.
- Acceptance Criteria:
  - Kláruð recurring task býr til næsta instance sjálfvirkt.
  - No duplicate generation.
- Tasks:
  - [ ] D1 schema breyting fyrir recurrence fields.
  - [ ] API validation + generation logic.
  - [ ] UI controls fyrir recurrence.
  - [ ] Integration tests fyrir edge-cases.
- Depends on: #1

## 4) Quick Add Syntax
- Priority: P2
- Labels: `feature`, `frontend`, `ux`
- Why: Hraðari innsetning, færri smelli.
- Scope: Parse-a `#tag`, `@time`, `!priority` úr einni línu.
- Acceptance Criteria:
  - Input eins og `Kaupa mjólk #innkaup @20:00 !hátt` parse-ast rétt.
  - Villa í syntax stoppar ekki task creation (graceful fallback).
- Tasks:
  - [ ] Parser spec + test-cases.
  - [ ] UI quick-add field.
  - [ ] Mapping í núverandi create-task API.
  - [ ] Unit tests fyrir parser.

## 5) Search & Filters
- Priority: P2
- Labels: `feature`, `frontend`, `backend`, `performance`
- Why: Auðveldara að finna verkefni í stærri listum.
- Scope: Leit í title/tag + status/date filters.
- Acceptance Criteria:
  - Leitarsvörun <200ms við venjulegt álag.
  - Síur má sameina án rangrar niðurstöðu.
- Tasks:
  - [ ] API query parameters fyrir leit/síur.
  - [ ] UI search + filter controls.
  - [ ] Index review í D1 ef þarf.
  - [ ] Performance benchmark script.
- Depends on: #1

## 6) Undo + Trash Bin
- Priority: P2
- Labels: `feature`, `backend`, `frontend`, `safety`
- Why: Ver gegn mistökum.
- Scope: Soft-delete + restore innan 30 daga.
- Acceptance Criteria:
  - Eytt task/list fer í ruslafötu.
  - Restore skilar réttu state.
  - Hard delete eftir retention policy.
- Tasks:
  - [ ] Schema updates fyrir soft-delete metadata.
  - [ ] Trash endpoints (list/restore/purge).
  - [ ] UI fyrir ruslafötu.
  - [ ] Tests fyrir restore og permission checks.

## 7) Shared Lists with Roles
- Priority: P3
- Labels: `feature`, `auth`, `backend`, `frontend`
- Why: Deiling með raunverulegri samvinnu.
- Scope: `owner`, `editor`, `viewer` hlutverk.
- Acceptance Criteria:
  - Viewer getur ekki breytt efni.
  - Editor getur uppfært verkefni en ekki eigandastillingar.
  - Owner getur stjórnað aðgangi.
- Tasks:
  - [ ] Access model + DB tables fyrir membership.
  - [ ] Authorization middleware á öllum list/task endpoints.
  - [ ] Invite/manage collaborators UI.
  - [ ] Security regression tests.
- Depends on: #1, #5

## 8) List Templates
- Priority: P3
- Labels: `feature`, `frontend`, `onboarding`
- Why: Fljótari gangsetning fyrir nýja notendur.
- Scope: 5-8 tilbúin templates (innkaup, ferðalag, vikuskipulag...).
- Acceptance Criteria:
  - Notandi getur stofnað lista úr template með einum smelli.
  - Template býr til rétt default tasks/tags.
- Tasks:
  - [ ] JSON source fyrir templates.
  - [ ] Template picker UI.
  - [ ] API support fyrir create-from-template.
  - [ ] Onboarding tracking metric.
- Depends on: #1

## Suggested Milestones
- Milestone A (2 vikur): #1, #2, #3
- Milestone B (vikur 3-6): #4, #5, #6
- Milestone C (vikur 7-10): #7, #8
