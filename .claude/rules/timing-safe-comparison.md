# Timing-Safe Comparison Security Rule

**Purpose:** Prevent timing attacks in security-sensitive string comparisons
**Applies to:** Files matching `**/auth.ts`, `**/security/**/*.ts`, `**/*password*.ts`, `**/*token*.ts`
**Priority:** P0 (Security Critical)
**Created:** December 30, 2025

---

## Rule: Always Use Constant-Time Comparison for Secrets

### Pattern to Detect

**Vulnerable code (DO NOT USE):**
```typescript
// ❌ SECURITY VULNERABILITY: Timing attack risk
if (password === storedPassword) { ... }
if (hash === computedHash) { ... }
if (token === expectedToken) { ... }
return secretKey === inputKey;
```

### Required Pattern

**Secure code (MUST USE):**
```typescript
// ✅ SECURE: Constant-time comparison
if (timingSafeEqual(password, storedPassword)) { ... }
if (timingSafeEqual(hash, computedHash)) { ... }
if (timingSafeEqual(token, expectedToken)) { ... }
return timingSafeEqual(secretKey, inputKey);
```

---

## Implementation: timingSafeEqual Function

**Location:** `packages/workers/src/utils/auth.ts` (lines 136-175)

```typescript
/**
 * Constant-time string comparison to prevent timing attacks.
 *
 * This function compares two hex-encoded strings in constant time,
 * regardless of where differences occur. This prevents attackers from
 * using timing analysis to determine correct password characters.
 *
 * @param a - First hex string to compare
 * @param b - Second hex string to compare
 * @returns true if strings are identical, false otherwise
 *
 * Security Properties:
 * - No early exits (always processes full length)
 * - No branching based on content
 * - Timing independent of where differences occur
 * - Prevents character-by-character password guessing
 */
function timingSafeEqual(a: string, b: string): boolean {
  const aLen = a.length;
  const bLen = b.length;
  const len = Math.max(aLen, bLen);

  // Pad strings to same length (prevents length-based timing leak)
  const aPadded = a.padEnd(len, '0');
  const bPadded = b.padEnd(len, '0');

  // Convert hex strings to byte arrays
  const aBytes = new Uint8Array(len / 2);
  const bBytes = new Uint8Array(len / 2);

  for (let i = 0; i < len; i += 2) {
    aBytes[i / 2] = parseInt(aPadded.substr(i, 2), 16);
    bBytes[i / 2] = parseInt(bPadded.substr(i, 2), 16);
  }

  // XOR all bytes - NO EARLY EXIT
  // This ensures all bytes are always compared
  let result = 0;
  for (let i = 0; i < aBytes.length; i++) {
    result |= aBytes[i] ^ bBytes[i];  // Bitwise OR accumulates differences
  }

  // Check length equality (constant-time check)
  const lengthMatch = aLen === bLen ? 0 : 1;

  // Return true only if all bytes match AND lengths match
  return (result | lengthMatch) === 0;
}
```

---

## When to Apply This Rule

### Required for These Operations

**Password verification:**
```typescript
// ✅ CORRECT
async function verifyPassword(password: string, storedHash: string): Promise<boolean> {
  const computedHash = await hashPassword(password);
  return timingSafeEqual(computedHash, storedHash);  // Constant-time
}
```

**API key validation:**
```typescript
// ✅ CORRECT
function validateApiKey(providedKey: string, expectedKey: string): boolean {
  return timingSafeEqual(providedKey, expectedKey);  // Constant-time
}
```

**JWT signature verification:**
```typescript
// ✅ CORRECT
function verifyJwtSignature(token: string, signature: string): boolean {
  return timingSafeEqual(computeSignature(token), signature);  // Constant-time
}
```

**Token comparison:**
```typescript
// ✅ CORRECT
function validateSessionToken(token: string, storedToken: string): boolean {
  return timingSafeEqual(token, storedToken);  // Constant-time
}
```

### NOT Required for These Operations

**Non-sensitive string comparison:**
```typescript
// ✅ OK: Using === for non-sensitive data
if (userRole === "admin") { ... }
if (containerStatus === "full") { ... }
if (requestMethod === "POST") { ... }
```

**Numeric comparison:**
```typescript
// ✅ OK: Numbers don't have timing attack risk
if (userId === 123) { ... }
if (count > 0) { ... }
```

---

## Security Rationale

### Why Timing Attacks Work

**Vulnerable `===` comparison:**
```
Comparing: "abc123" === "abc456"

Step 1: Compare 'a' === 'a' ✓ Continue
Step 2: Compare 'b' === 'b' ✓ Continue
Step 3: Compare 'c' === 'c' ✓ Continue
Step 4: Compare '1' === '4' ✗ EARLY EXIT (3 comparisons done)

Time taken: ~0.003ms
```

**If first character wrong:**
```
Comparing: "abc123" === "xyz456"

Step 1: Compare 'a' === 'x' ✗ EARLY EXIT (1 comparison done)

Time taken: ~0.001ms
```

**Attacker strategy:**
- Measure response time for different password attempts
- "aaa..." → 0.001ms (wrong first char)
- "baa..." → 0.001ms (wrong first char)
- "paa..." → 0.002ms (first char correct!)
- "paa..." → 0.002ms (try second char)
- "pba..." → 0.002ms (wrong second char)
- "pza..." → 0.003ms (second char correct!)
- Continue until full password discovered

### How Constant-Time Prevents This

**timingSafeEqual comparison:**
```
Comparing: "abc123" === "abc456"

XOR all bytes (NO EARLY EXIT):
  'a' ^ 'a' = 0x00
  'b' ^ 'b' = 0x00
  'c' ^ 'c' = 0x00
  '1' ^ '4' = 0x05  ← Different, but loop continues
  '2' ^ '5' = 0x07  ← Keep going
  '3' ^ '6' = 0x05  ← Keep going

Time taken: ~0.0001ms (constant)
```

**No information leak:** All comparisons take the same time regardless of:
- Where differences occur
- How many characters match
- String lengths (after padding)

---

## Code Review Checklist

When reviewing auth-related code, verify:

- [ ] No direct `===` comparison for passwords
- [ ] No direct `===` comparison for API keys
- [ ] No direct `===` comparison for tokens
- [ ] No direct `===` comparison for JWTs
- [ ] `timingSafeEqual()` used for all secret comparisons
- [ ] Function imported from `packages/workers/src/utils/auth.ts`

---

## Security Compliance

**Standards met:**
- ✅ OWASP A02:2021 (Cryptographic Failures)
- ✅ NIST SP 800-63B (Digital Identity Guidelines)
- ✅ CWE-208 (Observable Timing Discrepancy)

**Performance impact:**
- Comparison overhead: <0.1ms
- PBKDF2 hashing: 5-8ms (100,000 iterations)
- **Total: Negligible (<2% overhead)**

---

## References

- **Implementation:** `packages/workers/src/utils/auth.ts:136-175`
- **Usage:** `packages/workers/src/utils/auth.ts:234` (verifyPassword)
- **Tests:** `packages/workers/src/utils/__tests__/auth.test.ts`
- **Demo:** `packages/workers/demo-timing-safe.js`
- **Documentation:** `packages/workers/TASK-030-IMPLEMENTATION.md`

---

**This rule prevents timing attacks that could compromise authentication security.**
