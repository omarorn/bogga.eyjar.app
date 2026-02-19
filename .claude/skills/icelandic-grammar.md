---
description: Review and auto-correct Icelandic text using GreynirCorrect via Yfirlestur.is API. Supports real-time input field checking and batch validation. Includes complete error code reference for spelling, grammar, punctuation, and style corrections.
---

# Icelandic Grammar Reviewer

Review Icelandic text for spelling, grammar, and declension errors using the Yfirlestur.is API (GreynirCorrect).

## Available Resources

### Yfirlestur.is API (GreynirCorrect)
REST API for grammar checking: `https://yfirlestur.is/correct.api`

```bash
# Check text for errors (POST with form-encoded body)
curl -X POST "https://yfirlestur.is/correct.api" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "text=Hún var með skilagjald"

# Alternative: JSON body
curl -X POST "https://yfirlestur.is/correct.api" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hún var með skilagjald"}'
```

### BÍN Lookup (Beygingarlýsing íslensks nútímamáls)
For word inflection lookups: `https://bin.arnastofnun.is/`

---

## Yfirlestur.is API Error Codes (GreynirCorrect)

Complete reference of annotation codes returned by the API.

### Stafsetningarvillur (Spelling Errors) — S-series

| Code | Lýsing | Dæmi |
|------|--------|------|
| S001 | Algeng stafsetningarvilla (úr unique_errors orðabók) | "aldrey" → "aldrei" |
| S002 | Sjaldgæfari villa (spelling module) | "sjónnvarpið" → "sjónvarpið" |
| S003 | Rangt mynduð orð (ErrorForms) | "manneskjan" → "manneskjan" |
| S004 | Sjaldgæft orð skipt út fyrir algengara | "Maðurin" → "Maðurinn" |
| S005 | Leiðrétting þar sem annotation tapaðist | — |

### Samsetningarvillur (Compound Errors) — C-series

| Code | Lýsing | Dæmi |
|------|--------|------|
| C001 | Endurtekið orð fjarlægt | "og og" → "og" |
| C002 | Ranglega samsett orð aðskilin | "kerfis breyting" ← "kerfisbreyting" |
| C003 | Ranglega aðskilin samsett orð sameinuð | "kerfi breyting" → "kerfisbreyting" |
| C004/w | Endurtekið orð (möguleg villa) | — |
| C005/w | Möguleg samsett orðaskipting eftir merkingu | — |
| C006 | Hluti samsetningar rangur | — |
| C007 | Fjölorða samsetning með sameinuðum fyrstu hlutum | — |

### Hástafa-/lágstafavillur (Capitalization) — Z-series

| Code | Lýsing | Dæmi |
|------|--------|------|
| Z001 | Orð á að byrja á lágstaf | "Danskan" → "danskan" |
| Z002 | Orð á að byrja á hástaf | "ísland" → "Ísland" |
| Z003 | Mánaðarheiti á lágstaf | "Janúar" → "janúar" |
| Z004 | Tölur á lágstaf | — |
| Z005/w | Upphæðir á lágstaf | — |
| Z006 | Skammstöfun á hástaf | — |

### Óþekkt orð (Unknown Words) — U-series

| Code | Lýsing |
|------|--------|
| U001 | Óþekkt orð sem ekki er hægt að túlka eða leiðrétta |

### Greinarmerki (Punctuation) — N-series

| Code | Lýsing | Dæmi |
|------|--------|------|
| N001 | Röng gæsalöpp/tilvitnunarmerki | „" vs "" |
| N002/w | Þrír punktar eiga að vera þrípunktur (…) | "..." → "…" |
| N003/w | Óformleg samsett greinarmerki | "??!!" |

### Skammstöfunarvillur (Abbreviations) — A-series

| Code | Lýsing |
|------|--------|
| A001 | Skammstöfun leiðrétt |
| A002 | Tóka úr WRONGDOTS lista leiðrétt sem skammstöfun |

### Stafsetningartillögur (Spelling Suggestions) — W-series

| Code | Lýsing |
|------|--------|
| W001 | Tillaga að útskiptingu |
| W002 | Listi af tillögum |

### Málfræðivillur — Fallvillur (Grammar Case Errors) — P_WRONG_CASE

| Code | Lýsing | Dæmi |
|------|--------|------|
| P_WRONG_CASE_þgf_þf | Þágufall notað í stað þolfalls | "með bókina" → "með bókinni" |
| P_WRONG_CASE_þf_þgf | Þolfall notað í stað þágufalls | — |
| P_WRONG_CASE_nf_þf | Nefnifall notað í stað þolfalls | "Ég sá hann" (nf→þf) |
| P_WRONG_CASE_þf_nf | Þolfall notað í stað nefnifalls | — |
| P_WRONG_CASE_nf_þgf | Nefnifall notað í stað þágufalls | — |
| P_WRONG_CASE_þgf_nf | Þágufall notað í stað nefnifalls | — |
| P_WRONG_CASE_ef_þgf | Eignarfall notað í stað þágufalls | — |
| P_WRONG_CASE_þgf_ef | Þágufall notað í stað eignarfalls | — |

**Skammstafanir:** nf=nefnifall, þf=þolfall, þgf=þágufall, ef=eignarfall

### Málfræðivillur — Aðrar (Other Grammar Errors) — P-series

| Code | Lýsing |
|------|--------|
| P001 | Röng forsetning í orðasambandi ("leita af" → "leita að") |
| P_WRONG_OP_FORM | Röng ópersónuleg sagnbeyging |
| P_NT_FsMeðFallstjórn | Forsetning með rangri fallstjórn |
| P_NT_EndingIR | Röng ending -ir |
| P_NT_EndingANA | Röng ending -ana |
| P_NT_Annara / P_NT_Annari / P_NT_Annarar | Rangt beygingarform af "annar" |
| P_NT_Einkunn | Villa í notkun "einkunn" |
| P_NT_SíðastLiðinn | Villa í "síðastliðinn" |
| P_NT_ÍTölu | Villa í töluorðanotkun |
| P_NT_Manns | Villa í notkun "manns" |

### Málfræðivillur — Aðvaranir (Grammar Warnings)

| Code | Lýsing |
|------|--------|
| P_NT_HeldurVilA/w | "Heldur en" vs "heldur vil ég" |
| P_NT_Síðan/w | Notkun "síðan" |
| P_NT_SemOg/w | "Sem og" notkun |
| P_NT_Að/w | Notkun "að" |
| P_NT_Komma/w | Kommunotkun |
| P_NT_SvigaInnihaldNl/w | Innihald í svigum |

### Stíl og varúð (Style & Warnings)

| Code | Lýsing |
|------|--------|
| Y001/w | Stílviðvörun fyrir orð |
| T001/w | Bannorð / óviðeigandi orð |
| V001/w | Tónn / málsnið viðvörun |

### Setningarvillur (Sentence-level) — E-series

| Code | Lýsing |
|------|--------|
| E001 | Setninguna var ekki hægt að þátta |
| E002 | Villa í þáttunartré |
| E003 | Ópersónuleg sögn með röngu frumlagsfalli |
| E004 | Setningin er líklega ekki á íslensku |
| E005 | Setningin er líklega of löng |
| E006 | Skammstöfun ætti að vera skrifuð út í formlegu máli |
| E007 | Upphrópunarmerki eiga ekki heima í formlegu máli |

---

## Error Category Mapping (for code)

```typescript
function getErrorCategory(code: string): string {
  if (!code) return 'villa';
  if (code.startsWith('S')) return 'stafsetning';
  if (code.startsWith('C')) return 'samsetning';
  if (code.startsWith('Z')) return 'hastafur';
  if (code.startsWith('U')) return 'othekkt';
  if (code.startsWith('N')) return 'greinarmerki';
  if (code.startsWith('A')) return 'skammstofun';
  if (code.startsWith('W')) return 'tillaga';
  if (code.startsWith('P')) return 'malfraedi';
  if (code.startsWith('E')) return 'setning';
  if (code.startsWith('Y') || code.startsWith('T') || code.startsWith('V')) return 'stilur';
  return 'villa';
}

function getErrorSeverity(code: string): 'error' | 'warning' | 'suggestion' {
  if (code.endsWith('/w')) return 'warning';
  if (code.startsWith('P_') || code.startsWith('S') || code.startsWith('E')) return 'error';
  if (code.startsWith('C') || code.startsWith('Z')) return 'warning';
  if (code.startsWith('W') || code.startsWith('Y')) return 'suggestion';
  return 'warning';
}
```

---

## Integration Patterns

### Pattern A: Real-time Input Checking (Greidi-style)

Check spelling as the user types, with debounce:

```typescript
// src/utils/proofreader.js
const YFIRLESTUR_API = 'https://yfirlestur.is/correct.api';

export async function checkIcelandicText(text: string) {
  if (!text || text.trim().length < 2) {
    return { corrections: [], correctedText: text, hasErrors: false };
  }

  const response = await fetch(YFIRLESTUR_API, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `text=${encodeURIComponent(text)}`,
  });

  if (!response.ok) {
    return { corrections: [], correctedText: text, hasErrors: false, apiError: true };
  }

  const data = await response.json();
  const corrections = [];

  for (const sentenceGroup of data.result || []) {
    for (const sentence of sentenceGroup) {
      for (const annotation of sentence.annotations || []) {
        if (annotation.suggest) {
          corrections.push({
            original: getOriginalText(sentence, annotation),
            suggestion: annotation.suggest,
            code: annotation.code,
            category: getErrorCategory(annotation.code),
            description: annotation.text || '',
          });
        }
      }
    }
  }

  return { corrections, hasErrors: corrections.length > 0 };
}

// Debounce: wait until user stops typing (800ms)
export function debounce(fn: Function, delay = 800) {
  let timer: ReturnType<typeof setTimeout> | null = null;
  return function (...args: any[]) {
    if (timer) clearTimeout(timer);
    timer = setTimeout(() => fn(...args), delay);
  };
}
```

### Pattern B: Batch Validation (Bók Lífsins-style)

Validate text after submission or during export:

```typescript
// src/services/icelandic-validator.ts
export interface GrammarIssue {
  original: string;
  corrected: string;
  rule: string;
  code: string;
  severity: 'error' | 'warning' | 'suggestion';
}

export async function validateIcelandicText(text: string): Promise<GrammarIssue[]> {
  const response = await fetch('https://yfirlestur.is/correct.api', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text }),
  });

  if (!response.ok) return [];
  const data = await response.json();
  const issues: GrammarIssue[] = [];

  for (const paragraph of data.result || []) {
    for (const annotation of paragraph.annotations || []) {
      issues.push({
        original: annotation.text || '',
        corrected: annotation.suggest || '',
        rule: annotation.code,
        code: annotation.code,
        severity: getErrorSeverity(annotation.code),
      });
    }
  }

  return issues;
}
```

---

## Common Icelandic Grammar Issues

### Fallbeygingar (Case Declensions)

| Fall | Spurning | Dæmi |
|------|----------|------|
| Nefnifall (nf) | Hver/hvað? | hestur, kona |
| Þolfall (þf) | Hvern/hvað? | hest, konu |
| Þágufall (þgf) | Hverjum/hverju? | hesti, konu |
| Eignarfall (ef) | Hvers? | hests, konu |

### Með + þágufall
"Með" takes dative case:
- ✅ "með skilagjaldi" (not "með skilagjald")
- ✅ "með plastinu" (not "með plastið")

### Í + þolfall (motion) vs þágufall (location)
- Motion: "Ég fer í skólann" (þolfall)
- Location: "Ég er í skólanum" (þágufall)

### Verb Conjugation (2nd person singular)
- ✅ "þú skilar" (not "þú skila")
- ✅ "þú setur" (not "þú setja")
- ✅ "þú ferð" (not "þú fara")

### Definite Article
- ✅ "endurvinnsluna" (accusative with article)
- ✅ "tunnuna" (accusative with article)
- ✅ "peninginn" (accusative singular with article)

---

## Review Process

1. **Identify text to review** - prompts, UI strings, translations
2. **Check via Yfirlestur.is** - automated grammar check
3. **Manual BÍN lookup** - verify specific word forms
4. **Apply corrections** - update source files

## Example Workflow

```typescript
// Before review
"Gosdósir með skilagjald skila þú í Endurvinnslan"

// Errors found:
// P_WRONG_CASE_þf_þgf: "skilagjald" → "skilagjaldi" (þágufall eftir "með")
// P_WRONG_VERB_FORM:   "skila þú" → "skilar þú" (2. persóna eintölu)
// P_WRONG_CASE_nf_þf:  "Endurvinnslan" → "endurvinnsluna" (þolfall)

// After correction
"Gosdósir með skilagjaldi skilar þú í endurvinnsluna"
```

## Files to Review in This Project

- `worker/src/services/gemini.ts` - AI prompts with Icelandic examples
- `worker/src/services/cloudflare-ai.ts` - AI prompts
- `src/locales/translations.ts` - UI translations
- `src/components/*.tsx` - Hardcoded Icelandic strings

## References

- [GreynirCorrect (GitHub)](https://github.com/mideind/GreynirCorrect) - Source code
- [Yfirlestur.is](https://yfirlestur.is/) - Web interface
- [Yfirlestur.is Docs](https://yfirlestur.is/doc/overview.html) - API documentation
- [BÍN](https://bin.arnastofnun.is/) - Beygingarlýsing íslensks nútímamáls
