# SPEC — Talk requests

**Created:** 2026-09-06  
**Status:** As-built V2  
**ADRs:** [0006](../adr/0006-talk-banner-expiry.md)

## Goal

Talk pings are a one-line Home banner with named copy and reply-based expiry, not wrapping chips.

## Background

`talk_banner.dart`, `partner_status_provider.dart` (`TalkSignal`), `talk_expiry.dart`, `acknowledgeSignal`, migrations `23_signal_acknowledge.sql`, `28_talk_ack_replies.sql`, `29_talk_ack_tonight.sql`.

## Requirements

1. **Send**: Talk sheet: Text → `text`, Call → `call`, Video → `video_call`.
   - Acceptance: Partner gets a pending signal + push

2. **Incoming copy**: `{name} wants to text|call|video chat` + Okay + ⋯.
   - Acceptance: Single row; Okay is `yes`; ⋯ opens In a bit / Tonight / Not now

3. **Sender copy**: Pending → `Waiting for {name}` (dismissible). After reply → `{name} said okay` / `will be there in a bit` / `said tonight` / `can’t right now`.
   - Acceptance: Sender card updates without flashing Waiting after a live ack

4. **Newest only**: Only the current live talk from `partnerStatus.talk` is shown. Local dismiss set hides it.
   - Acceptance: Old pending pings are not resurrected as Waiting

5. **Expiry**: Pending older than 8 hours hidden. Replies: yes 15m, soon 1h, not_now 2h, tonight until 6am local IANA.
   - Acceptance: `talkReplyExpiry` matches those durations

## Boundaries

**In scope:** Home banner, ack, expiry, push on send.

**Out of scope:** Actually placing a PSTN/cellular call — the app signals intent only. Widget must not show talk ([ADR-0008](../adr/0008-android-widget-no-talk.md)).

## Acceptance Criteria

- [ ] Incoming banner is one line with Okay + overflow
- [ ] Sender sees Waiting, then the named reply, without bounce
- [ ] Pending drops off after 8 hours
- [ ] Tonight uses 6am in profile timezone when available
