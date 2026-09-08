# UI / UX Guide - Zero Miles

## 1. Design Philosophy
Zero Miles is designed to be a **private sanctuary**. The interface must feel intimate, secure, modern, and distraction-free. 
- **Dark Mode First:** The app uses a dark theme natively to reduce eye strain, especially during late-night long-distance calls, and to make media (photos, emojis) pop.
- **Minimalist & Focused:** The UI avoids clutter, emphasizing the partner's content and connection signals.

## 2. Color Palette
The color scheme is designed to evoke warmth and modernity against a deep slate background.

### Background Colors
- **Background:** Warm near-black (#141014) — the room.
- **Surface:** Frosted umber (#231C21) — cards, dialogs, sheets.
- **Elevated:** (#2C242A)

### Brand / Accent Colors
- **Primary:** Honey rose (#E8A090) — primary buttons and highlights.
- **Secondary / Affection:** Deep rose (#E25C7A) — love drops.
- **Accent / Waiting:** Soft gold (#E0B56A).

### Text Colors
- **Primary Text:** Warm cream (#F6F0E8)
- **Secondary Text:** (#B5A8A0)

## 3. Typography
- **Primary Font:** `Inter` (body and labels)
- **Display Font:** `Fraunces` (wordmark and ritual titles)
- **Characteristics:** Clean, highly legible sans-serif.
- **Hierarchy:**
  - **Headings (H1/H2):** Bold, used for screen titles and daily questions.
  - **Body:** Regular weight for standard text and answers.
  - **Captions:** Small, secondary color for timestamps and minor labels.

## 4. User Experience (UX) Principles

### 4.1. "Give to Get" Mechanics
Features like *Daily Questions* and *Photo Sharing* require the user to input their side before viewing their partner's side.
- **UX Implementation:** Show a blurred or locked state with a clear call-to-action (e.g., "Answer to unlock your partner's response"). Ensure smooth transition animations upon unlocking.

### 4.2. Micro-Interactions & Emotional Feedback (V1)
- **Love Drops:** Haptic feedback and a toast when sending a kiss, hug, or sorry.
- **State Changes:** Smooth transitions between screens.

### 4.3. Navigation (V1)
- Home is the dashboard. Daily question / photo / outfit are reachable from Home. Settings from the gear.

## 4.4. V2 Home (shipped 2026-09-05 – 2026-09-06)
- **Couple scene:** Both avatars stay on Home, large, with mood poses (Angry stomps with 💢; sleep shows Zzz).
- **Love Drops:** Haptic + toast, and an emoji that **flies** from the sender’s seat to the receiver’s.
- **Talk banner:** One compact row above the couple scene. Never wrap chips over the avatars. Incoming: “{name} wants to call” + Okay + ⋯. Sender: “Waiting for {name}”, then their reply.
- **Mood sheet:** 2-column tiles (Happy, Excited, Tired, Sad, Angry, Devastated).
- **No bottom tab bar.** Canvas and voice are Home actions. Each seat has a living window for that person’s local time.

## 5. UI Components Guidelines
- **Buttons:** Rounded corners (e.g., `BorderRadius.circular(12)`), filled with Primary or Secondary color based on context.
- **Cards (Surfaces):** Use the Surface color (#1E293B) with subtle or no borders, maintaining a flat, modern aesthetic.
- **Avatars (V2):** Two layered person puppets side by side (You | Partner). Unpaired empty seat is a “Pair” affordance, not a second dummy body.
- **Empty States:** When a partner hasn't answered or uploaded yet, display friendly, encouraging illustrations or text rather than cold, blank screens.

## 6. Accessibility
- Maintain high contrast between text and background.
- Ensure touch targets for buttons and Love Drops are sufficiently large (minimum 48x48 logical pixels).
