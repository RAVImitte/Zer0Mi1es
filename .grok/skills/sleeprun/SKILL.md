---
name: sleeprun
description: >
  Resume Grok's dedicated sleepRun overnight UI/UX experiment for Zero Miles.
  Use when the user runs /sleepRun or /sleeprun, says sleepRun, or asks to
  continue the overnight shop, numbered ZM APKs, or the Zer0Mi1es-sleepRun worktree.
metadata:
  short-description: Resume dedicated sleepRun branch
---

# sleepRun pickup

This branch is dedicated to Grok. It is not Play / `production-release`.

## On invoke

Do this before any new UI work.

1. **Go to the worktree.** Use `/mnt/d/Chadukunta/zeromiles/Zer0Mi1es-sleepRun`.
   - If it is missing: `git -C /mnt/d/Chadukunta/zeromiles/Zer0Mi1es worktree add /mnt/d/Chadukunta/zeromiles/Zer0Mi1es-sleepRun sleepRun`
   - Never `git checkout sleepRun` inside `Zer0Mi1es-production-release` or `Zer0Mi1es` — those worktrees already hold other branches.
   - Do all later git/file work in the sleepRun worktree (`git -C` that path, or treat it as the project root).

2. **Sync.** `git -C …/Zer0Mi1es-sleepRun status -sb` and `git log --oneline -12`. Fetch `origin/sleepRun` if the network allows. WSL HTTPS often cannot prompt; Windows git from `D:\Chadukunta\zeromiles\Zer0Mi1es` can: `cmd.exe /c "cd /d D:\Chadukunta\zeromiles\Zer0Mi1es && git fetch origin sleepRun && git -C D:\Chadukunta\zeromiles\Zer0Mi1es-sleepRun merge --ff-only origin/sleepRun"` only if local has no conflicting work.

3. **Read** `docs/releases/SLEEPRUN.md` (Last progress, iteration plan, APK table).

4. **Open the reply with last progress**, then stop unless the user already asked to continue:
   - HEAD SHA and subject
   - Next iteration number (next unused `ZM NN`; after first night that is **ZM 46**)
   - What is on the Galaxy (ZM 00–45 unique packages; production `app.zeromiles` untouched)
   - Iteration grain (below)
   - Constraints: Home is the hub (no bottom tabs), two people only, widget must not show talk or kisses, no Play identity change, no backend unless the user asks

## Iteration grain

Do **not** commit and sideload every small UI or text tweak.

One iteration = related improvements on the same screen/flow, **one commit** with a detailed body, **one** numbered APK.

Club copy, labels, button ink, captions, empty states on the same surface. Keep a new gesture, feature, or global theme as its own iteration.

Identity patches (`applicationId` / `android:label` / extra `google-services` client) stay in `/mnt/d/Chadukunta/zeromiles/_zm-stage`, never on `sleepRun`. Sideload with `tool/sideload_commit_apks.py --from NN`.

## After work

Update **Last progress** in `docs/releases/SLEEPRUN.md`, add the new ZM row if an APK shipped, and push `origin/sleepRun` (Windows git from the main repo path if WSL cannot authenticate).
