## Conflict Detection Report

### BLOCKERS (0)

None.

### WARNINGS (3)

[WARNING] Competing acceptance variants for REQ-auth
  Found: docs/prd/PRD-zero-miles.md requires email + password sign-up and lists phone-number auth as out of scope
  Found: docs/archive/legacy-guides/prd_guide.md §3.1 requires "Phone/Email Auth: Secure sign-up/login" — same scope "authentication"
  Impact: Synthesis cannot pick without losing intent
  → Choose REQ-auth-v1 (email+password) or REQ-auth-v2 (phone/email), or split before routing. Canonical PRD and SPEC-auth-pairing both exclude phone OTP.

[WARNING] Competing acceptance variants for REQ-love-drops
  Found: docs/prd/PRD-zero-miles.md requires kiss, hug, or sorry landing on Home
  Found: docs/archive/legacy-guides/prd_guide.md §3.5 requires Kiss, Hug, Heart 💖, Sorry — same scope "love drops"
  Impact: Synthesis cannot pick without losing intent
  → Choose REQ-love-drops-v1 (no Heart) or REQ-love-drops-v2 (includes Heart), or split before routing. SPEC-home-presence lists Kiss / Hug / Sorry only.

[WARNING] Legacy-only requirements from superseded archive PRD
  Found: docs/archive/legacy-guides/prd_guide.md adds daily-question history (REQ-daily-question-history-legacy), photo reactions (REQ-photo-reactions-legacy), and unpairing/account deletion (REQ-unpairing-account-deletion-legacy) with no acceptance criteria
  Found: docs/prd/PRD-zero-miles.md does not define those three; docs/archive/legacy-guides/README.md says the legacy guide is superseded and must not be ingested
  Impact: Routing those IDs would reintroduce archive-only product work
  → Drop the legacy-only IDs, or promote them into the canonical PRD with acceptance criteria before routing

### INFO (8)

[INFO] Auto-resolved: ADR > DOC on Home pairing gate
  Note: docs/adr/0007-home-hub-no-tabs.md (Accepted, locked) says Home is not blocked on pairing; unpaired Home shows a Pair seat. docs/guides/architecture.md §2.3 says users cannot access the main app without being authenticated and securely paired. ADR wins. Synthesized intel keeps unpaired Home reachable.

[INFO] Auto-resolved: ADR > DOC on pairing token storage
  Note: docs/adr/0002-couple-private-rls.md (Accepted, locked) stores a hashed token only with no couple row until join. docs/guides/architecture.md §3.1 describes pairing tokens on `couples`. ADR wins.

[INFO] Auto-resolved: SPEC > DOC on daily media table names
  Note: docs/specs/SPEC-daily-rituals.md uses `daily_photos` / `daily_outfits`. docs/guides/architecture.md §3.1 names `photos` / `outfits`. SPEC wins.

[INFO] Auto-resolved: SPEC > PRD (legacy) on auth method
  Note: docs/specs/SPEC-auth-pairing.md and docs/prd/PRD-zero-miles.md require email + password; phone OTP is out of scope. docs/archive/legacy-guides/prd_guide.md §3.1 allows Phone/Email Auth. SPEC wins for constraints. Competing PRD variants remain in requirements.md as REQ-auth-v1 / REQ-auth-v2.

[INFO] Auto-resolved: SPEC > PRD (legacy) on love-drop types
  Note: docs/specs/SPEC-home-presence.md specifies Kiss / Hug / Sorry. docs/archive/legacy-guides/prd_guide.md §3.5 includes Heart 💖. SPEC wins for constraints. Competing PRD variants remain in requirements.md as REQ-love-drops-v1 / REQ-love-drops-v2.

[INFO] Citation cycles detected; independent per-doc extraction used
  Note: DFS three-color cycle detection on `cross_refs` found 12 citation cycles (max depth 7, cap 50 not hit). Cyclic SCC: ADR-0001, ADR-0002, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008, ADR-0009, ADR-0010, docs/prd/PRD-zero-miles.md, SPEC-android-widget, SPEC-auth-pairing, SPEC-home-presence, SPEC-security, SPEC-talk-requests; plus self-loop docs/gsd/GSD.md. Cycles are bidirectional ADR↔SPEC/PRD citations, not content contradictions. Extraction did not walk the ref graph, so no synthesis loop. All 26 classified docs were extracted independently.

[INFO] Archive and GSD docs classified despite skip notes
  Note: docs/README.md and docs/gsd/GSD.md say ingest `docs/prd/`, `docs/adr/`, `docs/specs/` only and skip `archive/` and `gsd/`. Classifiers still emitted JSON for docs/archive/legacy-guides/prd_guide.md, docs/archive/legacy-guides/README.md, docs/archive/v1/README.md, and docs/gsd/GSD.md. Those files were consumed as classified (PRD/DOC).

[INFO] No LOCKED-vs-LOCKED ADR contradiction
  Note: All ten ADRs are locked (Accepted). Decision statements agree on stack, RLS, feature layout, couple scene, puppet vs widget painter, talk banner, Home hub, Android widget snapshot, Android/iOS-only, and Angry replacing Overwhelmed. MODE=new; no existing CONTEXT.md locked-decision check.
