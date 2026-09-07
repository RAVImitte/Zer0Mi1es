# RLS proof (manual)

Do **not** run this in CI. It needs a real third-user JWT and a known `couple_id`. Without those secrets the script cannot prove anything, and CI must stay green.

**Project:** `vkcoeudqeegnftkytiqd`  
**URL:** `https://vkcoeudqeegnftkytiqd.supabase.co`

Use the **anon** key plus a user access token. Never the service-role key — that bypasses RLS.

## 1. Third user cannot SELECT a guessed couple

Users A and B are paired as `COUPLE_ID`. User T is signed in and is not a member.

```bash
export URL=https://vkcoeudqeegnftkytiqd.supabase.co
export ANON=...          # anon key
export T_JWT=...         # access token for user T
export COUPLE_ID=...     # guessed / known couple uuid
export CONN_ID=...       # optional guessed daily_connections.id

auth=(-H "apikey: $ANON" -H "Authorization: Bearer $T_JWT")

curl -s "${auth[@]}" "$URL/rest/v1/moods?couple_id=eq.$COUPLE_ID"
# expect []

curl -s "${auth[@]}" "$URL/rest/v1/daily_photos?couple_id=eq.$COUPLE_ID"
# expect []

curl -s "${auth[@]}" "$URL/rest/v1/daily_answers?select=*"
# expect [] (T has no couple answers)

# If a daily_connection_id leaked:
curl -s "${auth[@]}" "$URL/rest/v1/daily_answers?daily_connection_id=eq.$CONN_ID"
# expect []
```

Pass if every body is `[]` with HTTP 200. PostgREST + RLS hides rows; it does not 403.

The dashboard SQL editor often runs as postgres and **will not** prove RLS. Prefer curl with T’s JWT.

## 2. Photo lock

A has uploaded today’s photo. B has not.

As B:

```bash
export B_JWT=...
TODAY=$(date -u +%F)

curl -s -H "apikey: $ANON" -H "Authorization: Bearer $B_JWT" \
  "$URL/rest/v1/daily_photos?couple_id=eq.$COUPLE_ID&date=eq.$TODAY"
# expect [] or only B’s own row — A’s row must be absent
```

After B uploads their photo for that date, the same query must include A’s row.

Policy: `has_uploaded_photo_today` in `12_fix_photo_rls_recursion.sql` / `16_fix_photo_rls_and_reactions.sql`. The Home blur overlay is not the lock.
