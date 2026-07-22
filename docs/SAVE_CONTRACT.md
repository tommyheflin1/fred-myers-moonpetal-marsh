# Fred save contract v1

Core SaveService is the persistence mechanism; Fred owns this document. The root must be a dictionary with `schema_version: 1`. Unknown fields are ignored. Missing fields use defaults. Invalid IDs or values are filtered/clamped before state is applied.

```json
{
  "schema_version": 1,
  "game_version": "0.1.0",
  "core_version": "0.5.1",
  "adventure": {
    "active_level_id": "lily_leap",
    "checkpoint_id": "lily_leap:start",
    "unlocked_level": 1,
    "completed_levels": [],
    "quest_flags": [],
    "collected_story_items": [],
    "campaign_completions": 0,
    "best_level_times_ms": {}
  },
  "frog": {
    "hearts": 3,
    "energy": 100,
    "bugs_eaten_total": 0
  },
  "settings": {
    "reduced_motion": false,
    "reduced_flashing": false,
    "high_contrast": false,
    "larger_text": false,
    "audio_enabled": true,
    "haptics_enabled": true
  },
  "achievements": {"progress": {}, "unlocked": []},
  "inventory": {"owned": [], "equipped": {}}
}
```

## Invariants

- Stable level IDs: `lily_leap`, `the_deep`, `firefly_fen`, `predator_pass`, `moonpetal_rise`.
- `unlocked_level` is clamped to 1..5; completed IDs are unique known IDs in story order.
- `checkpoint_id` must belong to `active_level_id`; otherwise fall back to that level's start checkpoint.
- Hearts are clamped to 1..3 on durable load; energy to 0..100. Moment-to-moment position, predator transforms, invincibility frames, and raw input are never durable.
- `campaign_completions`, totals, and best times are non-negative. Best-time updates choose the lower positive value locally.
- Story item/quest IDs are allowlisted. The Sunken Acorn can only be set after its acquisition objective.
- Settings are restored before presentation starts. Authentication and cloud failure never block local load.

## Write boundaries

Write after a stable checkpoint, level completion, story-item acquisition, campaign completion, or settings change; flush on pause/quit through Core lifecycle. Use a transaction-like in-memory update then one atomic Core save. Never save during collision resolution.

## Migration and recovery tests

Fixtures must cover empty/missing save, valid v1, missing optional fields, unknown fields, invalid IDs, out-of-range values, corrupt primary with valid backup, both files corrupt, future schema refusal, and interrupted write. A future schema gets a non-destructive unsupported-version state; it must not be overwritten automatically.

## Cloud projection

Cloud sync is deferred. When enabled, project only monotonic/validated adventure fields. `completed_levels` uses stable union; `unlocked_level` and `campaign_completions` use maximum. Hearts, energy, checkpoint position, and best times require an explicit conflict rule before syncing. No cloud field becomes authoritative merely because the client sends it.

