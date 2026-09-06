# SYNTHESIS

Entry point for `gsd-roadmapper`. Mode: `new`. Precedence: ADR > SPEC > PRD > DOC.

## Doc counts by type

Classifications consumed: 26.

- ADR: 10
- PRD: 2
- SPEC: 7
- DOC: 7
- UNKNOWN: 0

Cycle detection: DFS three-color marking on `cross_refs`. Max depth 7 (cap 50 not hit). 12 citation cycles (bidirectional ADR↔SPEC/PRD refs + GSD.md self-loop). Extraction was per-document, not graph-walk. All 26 docs synthesized.

## Decisions locked

Locked: 10 (all ingest ADRs). Proposed: 0.

Sources:

- docs/adr/0001-flutter-supabase-stack.md
- docs/adr/0002-couple-private-rls.md
- docs/adr/0003-feature-first-layout.md
- docs/adr/0004-couple-scene-presence.md
- docs/adr/0005-puppet-vs-widget-painter.md
- docs/adr/0006-talk-banner-expiry.md
- docs/adr/0007-home-hub-no-tabs.md
- docs/adr/0008-android-widget-no-talk.md
- docs/adr/0009-android-ios-only.md
- docs/adr/0010-angry-replaces-overwhelmed.md

No LOCKED-vs-LOCKED contradiction.

## Requirements extracted

Count: 18.

Canonical (`docs/prd/PRD-zero-miles.md`): REQ-auth-v1, REQ-couple-pairing, REQ-daily-question, REQ-daily-photo-outfit, REQ-love-drops-v1, REQ-moods, REQ-talk-requests, REQ-voice-canvas, REQ-android-widget, REQ-home-couple-scene, REQ-home-hub-no-tabs, REQ-secrets-not-in-git, REQ-private-sanctuary.

Legacy (`docs/archive/legacy-guides/prd_guide.md`): REQ-auth-v2, REQ-love-drops-v2, REQ-daily-question-history-legacy, REQ-photo-reactions-legacy, REQ-unpairing-account-deletion-legacy.

Competing variant pairs: REQ-auth-v1 vs REQ-auth-v2; REQ-love-drops-v1 vs REQ-love-drops-v2.

## Constraints

Count: 37.

Type breakdown:

- api-contract: 12
- schema: 8
- nfr: 6
- protocol: 11

Sources: docs/specs/SPEC-auth-pairing.md, SPEC-security.md, SPEC-home-presence.md, SPEC-talk-requests.md, SPEC-android-widget.md, SPEC-daily-rituals.md, SPEC-voice-canvas.md.

## Context topics

Count: 7.

- Docs layout and ingest paths (docs/README.md)
- Legacy guides superseded (docs/archive/legacy-guides/README.md)
- V1 frozen packs (docs/archive/v1/README.md)
- Architecture stack and folders (docs/guides/architecture.md)
- UI / UX tokens and Home UX (docs/guides/ui-ux.md)
- V2 shipped release (docs/releases/V2.md)
- GSD operator playbook (docs/gsd/GSD.md)

## Conflicts

- blockers: 0
- competing-variants: 3 (2 PRD acceptance pairs + 1 legacy-only set)
- auto-resolved: 5 (plus 3 informational notes)

Detail: `.planning/INGEST-CONFLICTS.md`

## Per-type intel files

- `.planning/intel/decisions.md`
- `.planning/intel/requirements.md`
- `.planning/intel/constraints.md`
- `.planning/intel/context.md`

Do not treat this file as PROJECT.md, REQUIREMENTS.md, or ROADMAP.md. Those are produced downstream by `gsd-roadmapper`.
