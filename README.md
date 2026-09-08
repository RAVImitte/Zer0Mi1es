<div align="center">
  <h1> Zero Miles</h1>
  <p><em>An app designed to empathetically connect long-distance partners and bring you closer, no matter the distance.</em></p>
</div>

---

## 📱 About The App

Long-distance relationships can be challenging, but **Zero Miles** bridges the gap. Designed as an exclusive, private space for just you and your partner, the app helps you stay intimately connected through daily prompts, real-time emotional signaling, and visual sharing. 

Say goodbye to feeling disconnected and hello to meaningful daily interactions.

## ✨ Core Features (V1)

### 🔗 Secure Couple Pairing
Your private sanctuary. Securely link your account with your partner using a unique, time-sensitive pairing token. Once paired, the app becomes a dedicated space just for the two of you.
<br>
*(📸 Add screenshot/GIF here showing the pairing token screen)*

### 📝 Daily Connection Questions
Spark meaningful conversations every single day. The app generates a daily thought-provoking question for both of you. Answer the prompt to unlock and view your partner's response, keeping the conversation fresh and engaging.
<br>
*(📸 Add screenshot/GIF here showing the daily question screen)*

### 📸 Daily Photo & Outfit Sharing
Visually bridge the distance. Share your Outfit of the Day (OOTD) or a candid daily photo. To keep things fair and exciting, you can only see your partner's photo after you've uploaded yours!
<br>
*(📸 Add screenshot/GIF here showing the photo/outfit sharing feature)*

### 💧 Love Drops & Mood Sharing
Quick gestures (Kiss 💋, Hug 🤗, Heart 💖, Sorry 🥺) and a shared mood so they know how you feel.
<br>
*(📸 Add screenshot/GIF here showing the mood selector or love drop)*

### 🔔 Real-Time Connection Signals
Text / call / video pings plus Good Night / Good Morning, with a push to their phone.

---

## ✨ V3 (shipped 2026-09-08)

App version **3.0.0+3**. Sanctuary Home from `UI-experiment` on `main`:

- **Living windows** and time-of-day scene photos on Home
- **Home dock**, love-note cloud (8h), stacked voice log
- **Larger overlapping puppets**; pairing leaves Waiting when the couple forms
- **Note** love drop with emoji (`30_love_drop_note.sql`)

See [docs/releases/V3.md](docs/releases/V3.md).

## ✨ V2 (shipped 2026-09-05 – 2026-09-06)

App version **2.0.0+2**. Last 72 hours on `main` before V3:

- **Couple scene** — both of you on Home as layered person puppets; Love Drops fly between seats; sleep persists
- **Talk banner** — one line (“Gwen wants to call” + Okay + ⋯); replies expire (Okay 15m / In a bit 1h / Not now 2h / Tonight → 6am)
- **Moods** — 2-column sheet; **Angry** replaces Overwhelmed (stomp + 💢)
- **Android widget** — name, mood, scene, avatar snapshot (no talk/kisses)
- **Voice drops** and a **shared canvas** (strokes survive offline)
- **Sanctuary lighting** on Home (dawn / day / dusk / night)

---

## 🚀 Getting Started (For Developers)

Flutter client lives in `appcode/`. Supabase migrations and the push Edge Function live in `backend/supabase/`.

```bat
cd appcode
flutter run --dart-define-from-file=.env
```

See `appcode/README.md` and `AGENTS.md` (use `npx supabase` for DB commands). Product docs: **[docs/](docs/)** (PRD, ADR, SPEC).

---
*Built with Flutter (Android & iOS) and Supabase.*
