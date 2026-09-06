# SPEC — Voice drops and shared canvas

**Created:** 2026-09-06  
**Status:** As-built V2  
**ADRs:** [0002](../adr/0002-couple-private-rls.md), [0007](../adr/0007-home-hub-no-tabs.md)

## Goal

From Home, partners can send a short voice note and share a mural whose strokes survive offline.

## Background

`voice_drop/` + `24_voice_drops.sql` (max 15000 ms, 24h expiry, private `voice` bucket). `canvas/` + `25_canvas.sql` + `27_canvas_strokes.sql` (`strokes jsonb`, realtime).

## Requirements

1. **Voice record**: Home Voice action opens `showVoiceRecordSheet`. Duration `duration_ms` 1–15000. Storage `{coupleId}/{uid}/{id}.m4a` in private `voice` bucket. Default `expires_at` = now()+24h.
   - Acceptance: Insert rejected if duration > 15s. SELECT only while `expires_at > now()`

2. **Voice play**: `VoicePlayChip` on Home for inbound unexpired partner rows (signed URL ~1h).
   - Acceptance: Partner hears the clip; expired rows disappear from RLS

3. **Canvas**: `/canvas` from Home. Source of truth is `canvases.strokes` jsonb + Realtime (`27_canvas_strokes.sql`). `storage_path` / `canvas` bucket are vestigial — the app does not upload a PNG.
   - Acceptance: Partner opening canvas after being offline still sees saved strokes

## Boundaries

**In scope:** ≤15s voice, 24h TTL, persisted canvas.

**Out of scope:** Voice transcription, infinite gallery of old voice notes, vector export.

## Acceptance Criteria

- [ ] Voice longer than 15s cannot be stored
- [ ] Voice older than 24h is not readable
- [ ] Canvas strokes remain after both apps restart
