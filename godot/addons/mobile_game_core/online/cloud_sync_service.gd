class_name CloudSyncService
extends RefCounted

const UNION_FIELDS: Array[String] = ["completed_levels", "owned_cosmetics", "unlocked_achievements"]
const MAX_FIELDS: Array[String] = ["unlocked_level", "campaign_completions", "prestige_rank", "lifetime_coins_earned"]
const SERVER_FIELDS: Array[String] = ["coins"]

static func resolve(local: Dictionary, remote: Dictionary) -> Dictionary:
    var local_revision := maxi(0, int(local.get("revision", 0)))
    var remote_revision := maxi(0, int(remote.get("revision", 0)))
    if local_revision > remote_revision:
        return {"winner": "local", "revision": local_revision, "payload": _payload(local).duplicate(true)}
    if remote_revision > local_revision:
        return {"winner": "remote", "revision": remote_revision, "payload": _payload(remote).duplicate(true)}
    var local_payload := _payload(local)
    var remote_payload := _payload(remote)
    if JSON.stringify(local_payload) == JSON.stringify(remote_payload):
        return {"winner": "equal", "revision": local_revision, "payload": local_payload.duplicate(true)}
    var merged := remote_payload.duplicate(true)
    for field in UNION_FIELDS:
        var values: Array = []
        for value: Variant in remote_payload.get(field, []):
            if value not in values: values.append(value)
        for value: Variant in local_payload.get(field, []):
            if value not in values: values.append(value)
        values.sort()
        merged[field] = values
    for field in MAX_FIELDS:
        merged[field] = maxi(int(local_payload.get(field, 0)), int(remote_payload.get(field, 0)))
    for field in SERVER_FIELDS:
        merged[field] = remote_payload.get(field, 0)
    return {"winner": "merged", "revision": local_revision, "payload": merged}

static func next_upload(resolution: Dictionary) -> Dictionary:
    return {"expected_revision": int(resolution.get("revision", 0)), "payload": (resolution.get("payload", {}) as Dictionary).duplicate(true)}

static func _payload(envelope: Dictionary) -> Dictionary:
    var value: Variant = envelope.get("payload", {})
    return value if value is Dictionary else {}

