# GSD on Zero Miles

How to use **GSD (Git. Ship. Done.)** on this app without fighting the repo layout or Grok’s working directory. Product truth is **`main`** (`D:\Chadukunta\zeromiles\Zer0Mi1es`).

GSD is already installed on this machine (standard profile, Grok). It is **not** initialized in the Zero Miles repo yet. There is no `.planning/` folder in the git root. This file is the playbook for turning that on and using it well.

**One copy:** `docs/gsd/GSD.md` in the git repo. A stub at repo-root `GSD.md` points here. Do not keep copies in sibling worktrees or in `D:\Chadukunta\zeromiles\docs\`.

---

## 0. The one rule that makes or breaks GSD

**Start Grok inside the git worktree you want to change. Never from `C:\Users\ravim`.**

GSD looks for `.planning/` in the current working directory (the git root). Every “where are we?” from the Windows home folder will say “no planning structure” even if the app is half-built.

| What you want to change | Open a terminal here, then run `grok` |
|---|---|
| Current product (`main`) | `D:\Chadukunta\zeromiles\Zer0Mi1es` |
| Extra worktree `feature` (older) | `D:\Chadukunta\zeromiles\Zer0Mi1es-feature` |
| Extra worktree `UI-experiment` (older) | `D:\Chadukunta\zeromiles\Zer0Mi1es-UI-experiment` |

Default to **`main`**. Dual avatars, compact talk banner, Angry mood, and the Android widget are already on `main`.

From WSL:

```bash
cd /mnt/d/Chadukunta/zeromiles/Zer0Mi1es
grok
```

From cmd:

```bat
cd /d D:\Chadukunta\zeromiles\Zer0Mi1es
grok
```

Confirm with `pwd` / `cd` in the Grok session. You should see `Zer0Mi1es` — not `C:\Users\ravim`.

---

## 1. What GSD is (and is not)

GSD is a **phase machine with memory**, not a better chat.

| Without GSD (how we’ve been working) | With GSD |
|---|---|
| Two Grok sessions, two branches, no shared memory | `.planning/STATE.md` is the memory |
| “ok now I got another idea” mid-feature | Ideas go to discuss / capture, not into the current execute |
| Talk-banner bugs fixed by looping the same prompt | A plan with an acceptance check, then `/gsd-verify-work` |
| “where are we?” needs archaeology | `/gsd-progress` |

**Do not** run the full phase loop for a one-line copy change. That is `/gsd-quick`. Full GSD is for features that touch Flutter + Supabase + two phones.

---

## 2. Repo facts GSD must know

Zero Miles is a **brownfield** Flutter + Supabase couple app. Pairing, dual-avatar Home, moods (including Angry), love-drop flights, compact talk banner, daily question/photo/OOTD, voice drops, canvas, push, and the Android presence widget already exist on `main`.

```
D:\Chadukunta\zeromiles\                 folder only (not a git repo)
  README.md                              points here
  Zer0Mi1es\                             git root, branch main  ← work here
    docs\                                ALL app docs (prd/ adr/ specs/ gsd/)
    appcode\                             Flutter
    backend\supabase\
    AGENTS.md
  Zer0Mi1es-feature\                     extra worktree — no extra docs
  Zer0Mi1es-UI-experiment\               extra worktree — no extra docs
```

**Git root is the worktree folder, not `appcode\`.** GSD must run at `Zer0Mi1es*` so `.planning/` sits next to `appcode/` and `backend/`.

Installed GSD commands (standard profile — these are the ones Grok will actually load):

| Command | Use it for |
|---|---|
| `/gsd-onboard` | First-time setup of this existing repo |
| `/gsd-map-codebase` | Refresh “how the code is shaped” after a big merge |
| `/gsd-ingest-docs` | Fold PRD / architecture / UI into `.planning/` |
| `/gsd-new-project` | Only if onboard tells you to; do not start greenfield |
| `/gsd-discuss-phase N` | Lock product decisions before a plan |
| `/gsd-plan-phase N` | Write an executable `PLAN.md` |
| `/gsd-execute-phase N` | Implement the plan, atomic commits |
| `/gsd-verify-work N` | UAT against the *goal*, not the task list |
| `/gsd-progress` | Where am I / what next |
| `/gsd-quick …` | Small change with a commit, no roadmap phase |
| `/gsd-pause-work` | End of session handoff |
| `/gsd-resume-work` | Next session, pick up the handoff |
| `/gsd-code-review` | Review a finished phase |
| `/gsd-workspace` | Isolated extra copy (usually skip — you already have worktrees) |
| `/gsd-help` | Command reference |

Commands in the *full* GSD profile (`/gsd-debug`, `/gsd-ship`, `/gsd-capture`, `/gsd-fast`) are **not** installed. Add them later with `/gsd-surface` → profile `full` only if you miss them.

---

## 3. First-time setup (do this once)

Do it on **`main`** (`Zer0Mi1es`), then merge `.planning/` into the feature branches. That way every worktree shares the same product memory.

### 3.1 Node in WSL

GSD’s `gsd-tools.cjs` shells out to `node`. This WSL user has Windows `node.exe` / `npm` on PATH, but **no Linux `node` binary**. Until that exists, GSD queries fail with `node: command not found`.

Fix (pick one):

```bash
# A. Linux Node (preferred)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# B. Quick alias for this shell
alias node='node.exe'
```

Confirm: `node -v` prints a version.

### 3.2 Bring product docs into the git repo

GSD ingest looks **inside the git root**. Docs already live in `docs/prd/`, `docs/adr/`, `docs/specs/`. Do not copy from the parent folder.

Do **not** ingest `docs/archive/` (V1 PDFs, legacy guides). Ingest **prd + adr + specs** only.

### 3.3 Onboard

From `D:\Chadukunta\zeromiles\Zer0Mi1es`:

```text
/gsd-onboard
```

That runs, in order:

1. `/gsd-map-codebase` — writes `.planning/codebase/` (stack, architecture, conventions)
2. Doc ingest — PRD + architecture + UI → requirements + roadmap
3. Project init — `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`

When it asks what is already done, be blunt:

- **V1 done:** auth, couple pairing + RLS, daily question, daily photo, OOTD, basic moods/love drops, pings, push
- **V2 done (2026-09-05 – 2026-09-06):** couple scene, layered puppets, compact talk banner, Angry mood, Android widget, voice drops, canvas, sanctuary lighting — see `docs/releases/V2.md` and `docs/prd/PRD-zero-miles.md` §6
- **Not done / later:** iOS widget, shared calendar — do **not** re-plan pairing or V2 Home
- There is **no** `AvatarViewModel` / `watchPartnerEvents`. Presence is `coupleSceneProvider` + `layered_person_avatar.dart`. `PersonPainter` is widget-snapshot only.

### 3.4 Commit `.planning/`

`.planning/` is not gitignored. Commit it on `main`. That is the whole point — the next Grok session can read it.

```bat
cd /d D:\Chadukunta\zeromiles\Zer0Mi1es
git add .planning docs
git commit -m "Add GSD planning memory and usage guide"
```

Keep `.planning/` on `main`. Extra worktrees do not need a copy unless you actually work there.

---

## 4. Daily decision tree

```
Lost, or “where are we?”
        →  /gsd-progress
           (must be in the worktree)

Small, obvious change
  rename a mood, copy, padding, one widget bug
        →  /gsd-quick compact the talk banner so it stays one line

Small but fuzzy
  “make the talk card feel native”
        →  /gsd-quick --discuss compact the talk request card

New slice of product
  dual-avatar Home, presence widget, new ping type
        →  /gsd-discuss-phase N
        →  /gsd-plan-phase N
        →  read PLAN.md. If wrong, say so. Do not execute a bad plan.
        →  /gsd-execute-phase N
        →  /gsd-verify-work N   (two phones)

Session ending
        →  /gsd-pause-work

Next morning
        →  same worktree, then /gsd-resume-work
```

If you do not know which command: `/gsd-progress --do "fix the they-want-to-call card flicker"`. It routes. It does not do the work itself.

---

## 5. The real loop (90% of GSD)

Do these **in the project directory**, in order.

### 1. `/gsd-discuss-phase N`

Grok asks how you want it built. Answer in product language, not Dart.

Zero Miles examples of things that belong in `CONTEXT.md`:

- Both avatars stay on Home at all times, big, with live mood animations
- Talk request is one line: “{name} wants to call” + Okay + overflow
- Okay / In a bit / Not now expire at 15m / 1h / 2h
- Overwhelmed is gone; Angry has a stomp/scowl
- Features are couple-private; RLS is non-negotiable
- Android first; keep iOS from regressing

This file is how later agents stop guessing. Skip discuss and you get the talk-banner-that-wraps-onto-the-avatars again.

### 2. `/gsd-plan-phase N`

Produces `PLAN.md` with tasks. **Read it.** If it wants to rewrite `CoupleRepository` for a Home UI change, reject it.

### 3. `/gsd-execute-phase N`

Implements in waves, one commit per task. Let it commit. Do not also “ok push to git” in a second chat on the same files.

### 4. `/gsd-verify-work N`

Checks the **goal** (“Gwen’s phone shows Ravi’s Angry animation within a second”), not “files exist.”

For this app, verification that is not two-device is incomplete. See §8.

### 5. Repeat for the next phase

`/gsd-progress` tells you the next command. `/gsd-progress --next` just runs it.

---

## 6. `/gsd-quick` vs a phase

| Use `/gsd-quick` | Use a phase |
|---|---|
| Talk banner flicker / bounce-back | Dual-avatar Home as a product change |
| Overwhelmed → Angry + grid restyle | Android home-screen presence widget |
| Expiry 15m / 1h / 2h | New ping type, new table, new RLS |
| Copy, spacing, animation polish | Anything that needs a CONTEXT.md decision |

Quick tasks live in `.planning/quick/` and show up in `STATE.md`, **not** in `ROADMAP.md`. That is correct — they are not milestone phases.

Useful flags:

```text
/gsd-quick compact talk banner to one line
/gsd-quick --discuss restyle the mood sheet as a 2-column grid
/gsd-quick --validate add Angry avatar animation
/gsd-quick list
/gsd-quick resume <slug>
```

`--full` on quick is the whole pipeline for one task. Use it when the change is small in surface area but easy to get wrong (realtime card state).

---

## 7. Worktrees, branches, and not stepping on yourself

You already have three git worktrees of one repo. **Prefer those over `/gsd-workspace`.** GSD workspaces copy the repo again; you would then have six trees.

Rules:

1. **Default Grok to `main`.** Dual avatars + widget + Angry already landed there. Extra worktrees still exist; treat them as leftover, not as current product.
2. **`.planning/` is per worktree working copy.** Create it on `main` and commit it there.
3. **One Grok session per worktree** if you do open a side branch. Do not edit Home from two chats at once.
4. **Pause before you walk away.** `/gsd-pause-work` writes `.continue-here.md` and a WIP commit. Next session: same folder, `/gsd-resume-work`.
5. If you must explore a risky idea without touching these trees, then `/gsd-workspace --new`.

Product on `main` (2026-09-06): couple scene (both layered avatars), compact talk banner, Angry mood, Android widget, `PersonPainter` only for the widget snapshot. Compile/cleanup of the UI-experiment + feature merge may still be local until you commit.

---

## 8. Two-phone verification (non-negotiable)

Zero Miles is a **two-user realtime** app. A green Flutter analyze is not UAT.

For any phase that touches Home, moods, love drops, talk/call, pairing, or push:

1. Install the same build on two accounts (S23 + emulator, or two emulators).
2. Walk the actual couple loop GSD listed in the phase goal.
3. Watch the **other** phone, not the one you tapped.

Minimum scripts to keep in CONTEXT.md / UAT:

- A sets mood Angry → B’s avatar stomps (💢) and the Android widget updates
- A sends a love drop → it flies across the couple scene on B; A does not get a ghost echo
- A taps call → B sees “{name} wants to call” one line, not a wrapping chip row
- B taps Okay → A’s card becomes “{name} said okay” without flashing “Waiting…”
- Unanswered ping expires after 8 hours. Replies: Okay 15m, In a bit 1h, Not now 2h, Tonight until 6am
- Pairing still locks a third user out

If `/gsd-verify-work` tries to skip devices, stop it and paste the script.

After gaps: `/gsd-plan-phase N --gaps` then execute those fix plans. Do not vibe-fix in a third chat.

---

## 9. Tips and tricks

### Session hygiene

- **`/clear` then the GSD command** when Grok tells you to. Stale chat is how the talk-banner fix got retried in a loop.
- One intent per session. “Continue the dual avatar plan” in one chat. “Install GSD” in another. Mixing them is how this home-folder session lost the repo.
- If you only remember one command, it is `/gsd-progress`.

### What to tell discuss / CONTEXT

Lock **behavior**, not widgets:

- Bad: “use a Wrap of FilterChips”
- Good: “one row, their first name, Okay visible, other replies behind ⋯, never covers avatars”

Write down expiry rules, whose name is shown, and what the *sender* sees. Those were the actual bugs.

### Keep agents inside existing patterns

The app is feature-first (`lib/features/{auth,couple,home,avatar,...}`), Riverpod, GoRouter, Supabase repositories. A plan that invents a new state library or a second routing package is wrong — reject it.

Point GSD at:

- `appcode/lib/features/avatar/presentation/couple_scene_view_model.dart`
- `appcode/lib/features/avatar/presentation/widgets/layered_person_avatar.dart`
- `appcode/lib/features/home/presentation/widgets/talk_banner.dart`
- `partner_presence.dart` / `partner_status_provider.dart`
- `appcode/lib/features/home/data/home_widget_sync.dart` + `person_painter.dart` (widget only)
- `backend/supabase/migrations/`
- `AGENTS.md` → `npx supabase`, project `vkcoeudqeegnftkytiqd`

### Migrations

New tables or RLS belong in `backend/supabase/migrations/`, not “run this in the SQL editor and forget.” GSD should add a numbered SQL file. You still run `npx supabase` from the backend folder, per `AGENTS.md`.

### Do not ingest this GSD guide as a PRD

`docs/gsd/GSD.md` is operator docs. If ingest offers to treat it as a SPEC, skip it. Ingest `docs/prd/`, `docs/adr/`, `docs/specs/` only. Skip `docs/archive/`.

### Refresh the map after big merges

Home is already a couple scene on `main`. After the next large merge:

```text
/gsd-map-codebase
```

A stale map that still describes `AvatarViewModel` or a single partner circle is wrong.

### Commit discipline

Let `/gsd-execute-phase` and `/gsd-quick` commit. Then you say “push” once. Two chats committing the same tree is how `main` / `feature` / `UI-experiment` drift.

Push stays manual (you’ve been doing this):

```bat
git push -u origin HEAD
```

### When Grok starts coding without a plan

Stop it. For a feature: discuss → plan → **you read the plan** → execute. For a nit: `/gsd-quick`. Raw “fix that shit” is what produced the wrapping talk chips.

### UI phases

Home, avatars, mood sheet, talk banner are UI. Discuss them. If you later enable the UI cluster (`/gsd-surface` → enable `ui`), `/gsd-ui-phase N` writes a design contract first. Until then, paste screenshots into discuss and say “match this density.”

### Model / time

`/gsd-execute-phase` spawns subagents. Silence for a few minutes is normal. Do not re-send the same prompt; that is how retry loops start.

---

## 10. Suggested first week on this repo

1. Install Linux `node` in WSL (§3.1).
2. `cd` into `Zer0Mi1es` (main). Start Grok there.
3. Copy PRD / architecture / UI docs into `Zer0Mi1es\docs\` (§3.2).
4. `/gsd-onboard`. Mark shipped Home presence (dual avatars, talk banner, Angry, widget) as done. Next phases are net-new (iOS widget, calendar, …), not re-unifying branches.
5. Commit `.planning/` on `main`.
6. Do not start a parallel Grok in `C:\Users\ravim`.

---

## 11. “Where are we?” after GSD exists

From the worktree:

```text
/gsd-progress
```

You should see project name, progress bar, current phase, last summaries, blockers, and the next copy-paste command.

If it still says **No planning structure found**:

- You are in the wrong directory, or
- Onboard never ran, or
- You are on a worktree that never got the `.planning/` commit

`/gsd-new-project` is the wrong fix for Zero Miles. Use `/gsd-onboard`.

---

## 12. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| “No planning structure found” | Grok cwd is `C:\Users\ravim` | `cd` to a `Zer0Mi1es*` worktree, new session |
| `node: command not found` | WSL has `node.exe` but not `node` | Install Linux Node (§3.1) |
| Plan wants to rebuild pairing | Onboard thought the app was greenfield | Edit `ROADMAP.md` / `STATE.md`, mark pairing complete, `/gsd-progress` |
| Two chats editing Home | Two sessions, two worktrees, same feature | One session per worktree; `/gsd-pause-work` the other |
| UAT “passed” but phones disagree | Verify ran as a file checklist | `/gsd-verify-work N` with the two-phone script |
| Slash command missing | New Grok session before skills reload | New chat from the worktree; `/gsd-help` |
| Want debug / ship / capture | Standard profile | `/gsd-surface` then `profile full` (optional) |

---

## 13. Cheat sheet (print this)

```text
# every session
cd /d D:\Chadukunta\zeromiles\Zer0Mi1es-<branch>
grok
/gsd-progress

# first time only (main)
/gsd-onboard

# feature work
/gsd-discuss-phase N
/gsd-plan-phase N
/gsd-execute-phase N
/gsd-verify-work N

# nits
/gsd-quick <one sentence>

# stop / start
/gsd-pause-work
/gsd-resume-work

# lost
/gsd-progress --do "your intent in one sentence"
/gsd-help
```
