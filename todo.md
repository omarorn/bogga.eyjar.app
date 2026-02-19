# TODO - Notendamiðað þróunarplan fyrir Bogga

## Vinnustaða (live) — uppfært 2026-02-19

| # | Verkefni | Staða | Vinnur |
|---|----------|-------|--------|
| — | Deploy + grunnuppsetning | ✅ KLÁRAÐ | Claude |
| — | Edit verkefni + tag datalist | ✅ KLÁRAÐ | Claude |
| 8 | Sniðmát fyrir lista | ✅ KLÁRAÐ | Codex |
| 1 | Dagssýn (Í dag / Á morgun / Seint) | ✅ MVP KLÁRAÐ | Claude + Codex |
| 4 | Hraðinnsláttur (#tag @dagsetning) | ✅ MVP KLÁRAÐ | Claude + Codex |
| 5 | Leit og síur | ✅ MVP KLÁRAÐ | Claude + Codex |
| 2 | Snjallar áminningar | ⏸ TODO | — |
| 3 | Endurtekin verkefni | ✅ MVP KLÁRAÐ | Codex |
| 6 | Undo + ruslafata | ✅ MVP KLÁRAÐ | Codex |
| 7 | Samvinna á listum | ✅ MVP KLÁRAÐ | Codex |

> **Samræmingarleiðbeiningar:** Dagssýn/leit/hraðinnsláttur = einungis `public/index.html`.
> Snjallar áminningar = þarf migration + `src/index.js` + `public/index.html`. Endurtekin MVP er komin án migration.
> Undo MVP er komið án migration (verkefni). Full list-ruslafata krefst migration. Samvinna MVP er komin án migration; full útgáfa krefst migration.
> Codex update: event-wiring komið fyrir dagssýn/síur og quick-add parser hook (`#tag`, `@í dag`, `@á morgun`, `@YYYY-MM-DD`).

## Markmið
Auka daglegt notagildi, minnka fjölda smella og bæta líkur á að notendur klári verkefni á réttum tíma.

## Forgangur 1 (næstu 2 vikur) - Quick wins með mikla notendavirði

### 1. Dagssýn: `Í dag` / `Á morgun` / `Seint`
- Ávinningur: Notandi sér strax hvað skiptir máli núna.
- Umfang: Nýir síuflipar + röðun eftir fresti.
- Acceptance criteria: Notandi getur skipt milli flipa og séð rétt verkefni í hverjum flokki.
- Staða: MVP lokið (filter chips + dagsetningarsíur í verkefnalista).

### 2. Snjallar áminningar (deadline reminders)
- Ávinningur: Færri gleymd verkefni.
- Umfang: Push/local áminningar fyrir fresti (t.d. 24 klst og 2 klst fyrir).
- Acceptance criteria: Notandi getur kveikt/slökkt á áminningum per verkefni.

### 3. Endurtekin verkefni
- Ávinningur: Sparar tíma í endurteknum daglegum verkum.
- Umfang: Daily/weekly/monthly reglur + sjálfvirk endurgerð.
- Acceptance criteria: Verkefni endurbirtist sjálfkrafa eftir að fyrra er klárað.
- Staða: MVP lokið (daily/weekly/monthly + sjálfvirk næsta task þegar status fer í `done`).

## Forgangur 2 (vikur 3-6) - Dýpri notkun og minni núningur

### 4. Hraðinnsláttur (quick add syntax)
- Dæmi: `Kaupa mjólk #innkaup @20:00 !hátt`
- Ávinningur: Mun hraðari innsetning.
- Acceptance criteria: Titill, tag og tími parse-ast rétt úr einni línu.
- Staða: MVP lokið fyrir `#tag`, `@í dag`, `@á morgun`, `@YYYY-MM-DD` (ekki enn `!hátt`).

### 5. Leit og síur
- Ávinningur: Notandi finnur fljótt verkefni í stórum listum.
- Umfang: Leit í titli/tag + síur fyrir stöðu og dagsetningar.
- Acceptance criteria: Leitarsvörun < 200ms á venjulegum listastærðum.
- Staða: MVP lokið (client-side leit + stöðu-/dagsetningarsíur).

### 6. Undo + ruslafata
- Ávinningur: Öryggi gegn mistökum.
- Umfang: Soft-delete + endurheimt innan 30 daga.
- Acceptance criteria: Eyddar færslur sjást í ruslafötu og má endurheimta.
- Staða: MVP lokið fyrir verkefni (soft-delete, restore, purge). Lista-ruslafata áfram TODO.

## Forgangur 3 (vikur 7-10) - Samvinna og varðveisla

### 7. Samvinna á listum
- Ávinningur: Raunveruleg deiling fyrir fjölskyldu/teymi.
- Umfang: Hlutverk `owner`, `editor`, `viewer`.
- Acceptance criteria: Rétt heimildastýring á öllum API-endapunktum.
- Staða: MVP lokið (owner + `viewer/editor` á share-link). Full user-to-user collaboration er áfram TODO.

### 8. Sniðmát fyrir lista
- Ávinningur: Nýr notandi byrjar hraðar.
- Umfang: 5-8 tilbúin sniðmát (innkaup, ferðalag, vikuskipulag o.fl.).
- Acceptance criteria: Notandi getur stofnað lista úr sniðmáti með einum smelli.

## Mælikvarðar (success metrics)
- +20% fleiri kláruð verkefni á viku.
- -30% færri verkefni sem fara yfir frest.
- 7 daga retention hækkar um 10%.
- Tími til að búa til fyrsta gagnlega lista < 2 mínútur.

## Tæknileg röð (ráðlögð)
1. Dagssýn og síur í API/UI.
2. Reminder pipeline (permissions, scheduling, delivery).
3. Recurring model í gagnagrunni + worker logic.
4. Quick add parser.
5. Soft-delete + recovery.
6. Collaboration roles og authorization audit.
