# Zero Miles docs

**This folder is the only living documentation for the app.**  
Git root: `Zer0Mi1es/` (branch `main`). Do not keep copies in sibling worktrees or in `D:\Chadukunta\zeromiles\docs\`.

App version: **2.0.1+3** — operator runbook: [releases/PRODUCTION.md](releases/PRODUCTION.md) · change sheet: [releases/CHANGE-SHEET.md](releases/CHANGE-SHEET.md)

## Layout

```
docs/
  README.md           ← you are here
  prd/                product requirements (GSD ingest)
  adr/                architecture decisions, locked (GSD ingest)
  specs/              as-built feature contracts (GSD ingest)
  guides/             narrative architecture + UI
  gsd/                how to run GSD on this repo
  legal/              privacy policy + support (host privacy.md before Play production)
  releases/           shipped milestone notes (V2, …), Play Data safety, production UAT
  archive/v1/         frozen V1 PDF/DOCX — do not ingest
  archive/legacy-guides/  superseded markdown — do not ingest
```

| Read this | When |
|---|---|
| [prd/PRD-zero-miles.md](prd/PRD-zero-miles.md) | What the product is (V1 vs V2 vs later) |
| [adr/](adr/) | Locked technical decisions |
| [specs/](specs/) | Feature contracts + acceptance |
| [guides/architecture.md](guides/architecture.md) | Stack and folders |
| [guides/ui-ux.md](guides/ui-ux.md) | Visual / Home UX |
| [releases/V2.md](releases/V2.md) | What shipped in V2 |
| [releases/PRODUCTION.md](releases/PRODUCTION.md) | 2.0.1+3 AAB, Play tracks, operator + UAT gates |
| [releases/CHANGE-SHEET.md](releases/CHANGE-SHEET.md) | What landed on production-release (also [CSV](releases/CHANGE-SHEET.csv)) |
| [legal/privacy.md](legal/privacy.md) | What we collect, couple RLS, deletion |
| [legal/support.md](legal/support.md) | Support email and how to delete / sign out |
| [releases/PLAY-DATA-SAFETY.md](releases/PLAY-DATA-SAFETY.md) | Play Console Data safety form |
| [gsd/GSD.md](gsd/GSD.md) | GSD operator playbook |

Precedence if they disagree: **ADR > SPEC > PRD > guide**.

GSD ingest: `/gsd-ingest-docs` from this git root. It picks up `docs/prd/`, `docs/adr/`, `docs/specs/` only. Skip `archive/` and `gsd/`.
