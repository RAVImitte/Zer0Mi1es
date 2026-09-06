# Product Requirements Document (PRD) - Zero Miles

## 1. Product Overview
**Zero Miles** is a mobile application designed exclusively for couples in long-distance relationships. It serves as a private sanctuary for just two people, bridging the physical gap through empathetic, daily, and real-time connection features.

**Mission:** To help partners stay intimately connected, share their daily lives, and communicate emotions effortlessly, no matter the distance.

## 2. Target Audience
- Couples in long-distance relationships.
- Partners who travel frequently for work.
- Any couple seeking a private, dedicated space for meaningful interaction outside of noisy social media or standard messaging apps.

## 3. Core Features & Requirements

### 3.1. Authentication & Profile
- **Phone/Email Auth:** Secure sign-up/login.
- **Avatar:** A presence representation of the partner on Home (V1). V2 replaces this with layered person puppets — see §6.
- **Profile Management:** Basic details, timezone, and connection status.

### 3.2. Secure Couple Pairing
- **Pairing Mechanism:** Users generate a secure, time-sensitive pairing token.
- **Linking:** The partner inputs the token to link the accounts. Once paired, the app transforms into a shared dashboard exclusively for the two users.
- **Unpairing/Account Deletion:** Ability to sever the connection or delete the account securely.

### 3.3. Daily Connection Questions
- **Daily Prompt:** The system generates a thought-provoking question for both partners every day.
- **Answer to Unlock:** A user must submit their answer to unlock and view their partner's response.
- **History:** Users can view a history of past questions and answers.

### 3.4. Daily Photo & Outfit (OOTD) Sharing
- **Daily Uploads:** Users can snap or upload a candid daily photo or their Outfit of the Day.
- **Fairness Mechanism:** The partner's uploaded photo remains blurred/hidden until the user uploads their own.
- **Reactions:** Ability to react to the partner's photos.

### 3.5. Real-Time Connection Signals & Moods (V1)
- **Mood Sharing:** Users can set an emotional state (Happy, Sad, Tired, …) that updates on the partner’s screen.
- **Love Drops:** Kiss 💋, Hug 🤗, Heart 💖, Sorry 🥺 — haptic + toast.
- **Pings:** Text / call / video request, plus Good Night / Good Morning, with a push to the partner.

## 4. Technical Architecture
- **Frontend:** Flutter (iOS & Android).
- **Backend/Database:** Supabase (PostgreSQL) with Row Level Security (RLS) to ensure data is strictly visible only to the paired couple.
- **State Management:** Riverpod (Flutter).
- **Routing:** GoRouter.
- **Push Notifications:** Firebase Cloud Messaging (FCM) and Supabase Edge Functions.

## 5. Security & Privacy
- **Row Level Security (RLS):** All tables (profiles, couples, messages, photos) must enforce policies that strictly allow access only to the user and their linked partner.
- **Private Data:** No social sharing features. The app is a closed loop between two users.

## 6. V2 (shipped 2026-09-05 – 2026-09-06)

App version **2.0.0**. Everything below landed in the last 72 hours on `main` (PRs #7–#10 plus merge cleanup).

### 6.1. Couple scene
- Home always shows **both** layered person puppets (bear / bunny seats).
- Outfit colors tint clothes. Love Drops **fly** from sender to receiver.
- Sleep (Good Night / Good Morning) is per-avatar and persists.

### 6.2. Talk banner
- One line: “{name} wants to call” + **Okay** + ⋯ (In a bit / Tonight / Not now).
- Sender sees “Waiting for {name}”, then the reply. No wrapping chips over avatars.
- Pending expires after 8 hours. Replies: Okay 15m, In a bit 1h, Not now 2h, Tonight until 6am local.

### 6.3. Moods
- Sheet is a 2-column grid: Happy, Excited, Tired, Sad, **Angry**, Devastated.
- Overwhelmed is retired; old rows still play as Angry (stomp + 💢).

### 6.4. Android home-screen widget
- Partner name, mood, time-of-day scene, painted avatar snapshot.
- Must **not** show talk requests or kisses.

### 6.5. Voice, canvas, sanctuary Home
- Voice drops from Home.
- Shared canvas; strokes persist when a partner is offline.
- Sanctuary lighting (dawn / day / dusk / night) on Home.

### 6.6. Platform
- Flutter client restructured for Android/iOS-only (`appcode/` + `backend/`).
- Push restored after JWT-required Edge Function deploy.
- Presence is `coupleSceneProvider` + `LayeredPersonAvatar`. No `AvatarViewModel` / `watchPartnerEvents`. `PersonPainter` is widget-snapshot only.

## 7. Later (after V2)
- Shared calendar and countdowns to next meeting.
- Shared playlists.
- iOS home-screen widget.
