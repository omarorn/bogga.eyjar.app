---
paths: "src/**/*.ts", "src/**/*.tsx", "src/**/*.astro", "src/**/*.jsx"
---

# Icelandic UI Text (for Icelandic projects)

**Purpose:** All user-facing text must be in Icelandic.

## Rules

✅ **Do:**
- Use Icelandic for ALL user-facing text
- Follow existing naming patterns
- Use Icelandic phone format: +354 XXX-XXXX
- Use Icelandic date/time formats: "fyrir 12 mín", "í gær"
- Support all Icelandic characters: á, ð, é, í, ó, ú, ý, þ, æ, ö

❌ **Don't:**
- Mix English and Icelandic in UI
- Use English placeholder text
- Hardcode English error messages

## Common UI Terms

| English | Icelandic |
|---------|-----------|
| Back | Til baka |
| Next | Áfram |
| Confirm | Staðfesta |
| Cancel | Hætta við |
| Save | Vista |
| Delete | Eyða |
| Edit | Breyta |
| Search | Leita |
| Settings | Stillingar |
| Login | Innskrá |
| Logout | Útskrá |
| Submit | Senda |
| Loading | Hleð... |
| Error | Villa |
| Success | Tókst |
| Not found | Fannst ekki |
| Required | Nauðsynlegt |

## Date/Time Formats

```typescript
// Relative time
"fyrir 2 mín"     // 2 minutes ago
"fyrir 1 klst"    // 1 hour ago
"í gær"           // yesterday
"fyrir 3 dögum"   // 3 days ago
```

## Error Messages

```typescript
const ERRORS = {
  required: 'Þessi reitur er nauðsynlegur',
  invalid_email: 'Ógilt netfang',
  too_short: 'Of stutt (lágmark {{min}} stafir)',
  server_error: 'Villa kom upp, reyndu aftur',
  not_found: 'Fannst ekki',
  unauthorized: 'Þú hefur ekki aðgang',
};
```
