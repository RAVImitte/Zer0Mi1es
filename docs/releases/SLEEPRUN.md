# sleepRun overnight shop

Unattended experiment line. **Not** Play / production-release.  
Branch: `sleepRun` from `main` (`a4b8add`). Worktree: `Zer0Mi1es-sleepRun`.

Each commit is one idea. In the morning, cherry-pick what you like:

```
git cherry-pick <sha>
```

or `git show <sha>` then take files.

Phone apps are **separate installs**. Launcher name is `ZM NN`. Android package is `com.example.zer0mi1es.zmNN` so they do not overwrite each other or Play `app.zeromiles`.

## How to shop

1. Open the numbered app on the Galaxy (`ZM 00`, `ZM 01`, …).
2. Match the number to the commit below.
3. `git cherry-pick <sha>` for keepers.
4. Skip docs-only and test-only commits (no APK).

Theme commits change global color; later UI commits sit on top of that palette.

## Constraints I kept

- Home is still the hub. No bottom tabs.
- Two people only. No social feed.
- Widget still does not show talk or kisses.
- No service-role in the app. No Play identity change.

## Phone apps

| App | SHA | Commit |
| --- | --- | --- |
| ZM 00 | `a4b8add` | base main |
| ZM 01 | `c5d8cb9` | theme: candlelit sanctuary palette |
| ZM 02 | `2cff778` | home: scene line and labeled daily rituals |
| ZM 03 | `af18caf` | auth: night wash and quieter tagline |
| ZM 04 | `ca9355b` | pair: six tiles for the join code |
| ZM 05 | `8c5f690` | feat: thinking-of-you affection |
| ZM 06 | `127b486` | home: invite-them seat and night sleep glow |
| ZM 07 | `8c38047` | talk: Okay sits on ink instead of white |
| ZM 08 | `efe18b5` | ritual: quieter daily-question save copy |
| ZM 09 | `fcb8b9d` | splash: quieter mark while routing settles |
| ZM 10 | `8e5d404` | auth: name-setup spinner matches the button ink |
| ZM 11 | `a040c16` | ritual: photo lock says share yours to see theirs |
| ZM 12 | `290dfa6` | feel: sent toast and mood caption are quieter |
| ZM 13 | `cb8ad4e` | home: settings partner copy is quieter |
| ZM 14 | `e25de06` | talk: tonight option has a caption |
| ZM 15 | `0c38e3f` | ritual: question header and waiting copy are quieter |
| ZM 16 | `dcf7c5f` | canvas: titled shared mural |
| ZM 17 | `0ac9e46` | outfit: rose and ink swatches, save sits on ink |
| ZM 18 | `1328b2b` | voice: mic sits on ink, gone in a day |
| ZM 19 | `d3585ac` | home: voice chip says they left a voice |
| ZM 20 | `dba71da` | ritual: photo titled today, capture sits on ink |
| ZM 21 | `a37dacd` | pair: join spinner matches the button ink |
| ZM 22 | `27880cd` | home: tap your seat to change outfit |
| ZM 23 | `dfaf04d` | ritual: question share sits on ink |
| ZM 24 | `9cd5284` | talk: sheet titled reach them |
| ZM 25 | `e6b236e` | ritual: photo cards titled theirs and yours |
| ZM 26 | `6e3299c` | pair: divider uses hairline |
| ZM 27 | `1151ddd` | feel: toast sits on a rose wash |
| ZM 28 | `adff4ae` | home: seat caption fallback is with you |
| ZM 29 | `a380f09` | auth: quieter create-account toggle |
| ZM 30 | `b975022` | outfit: they will match, quieter labels |
| ZM 31 | `ec0f617` | home: rituals labeled wear photo ask |
| ZM 32 | `c3dde34` | canvas: clear asks about the shared mural |
| ZM 33 | `e261015` | ritual: photo caption hint is a line for them |
| ZM 34 | `960606f` | feel: note sheet is a line for them |
| ZM 35 | `00c7fc5` | home: double-tap their seat to send a kiss |
| ZM 36 | `f56b165` | feel: thinking action labeled think |
| ZM 37 | `5c2e8cd` | ritual: waiting badges use candle, not orange |
| ZM 38 | `c78562f` | talk: not now has a caption |
| ZM 39 | `5f1d1c2` | home: hairline above the affection row |
| ZM 40 | `d9f50f8` | home: sleep and wake toast good night or morning |
| ZM 41 | `095bad5` | theme: rounder cards and sheets |
| ZM 42 | `71a3bc7` | home: settings sheet titled this room |
| ZM 43 | `b7901b6` | home: this-room menu hides behind more |
| ZM 44 | `ccc8983` | home: quieter scene lines |

Skipped (no UI): `bba603e` docs index, `676fd24` sceneLine tests, `fcf5a81` shop table, `1340ca9` sideload tool.

ZM 00–11 install first. ZM 12+ follow. Production **Zero Miles** (`app.zeromiles`) stays on the phone.
