extends SceneTree
const Service := preload("res://addons/mobile_game_core/online/golden_egg_discovery_service.gd")
const Store := preload("res://addons/mobile_game_core/online/golden_egg_secure_store.gd")

class Bridge:
    extends RefCounted
    var records: Dictionary = {}
    var fail_write := false
    var fail_read := false
    var writes := 0
    func flins_keychain_read(key: String) -> Dictionary:
        return {"ok": not fail_read, "found": records.has(key), "value": records.get(key, "")}
    func flins_keychain_write(key: String, value: String) -> int:
        writes += 1
        if fail_write:
            return ERR_CANT_CREATE
        records[key] = value
        return OK

var failures: Array[String] = []
var checks := 0

func make_service(bridge: RefCounted) -> RefCounted:
    var store := Store.new()
    store.configure("fictional-game", "fictional-egg", bridge)
    var service := Service.new()
    service.configure("fictional-game", "fictional-egg")
    service.attach_store(store)
    return service

func _init() -> void:
    var bridge := Bridge.new()
    var first := make_service(bridge)
    check(bridge.writes == 0 and first.website_request_count == 0, "startup reads only")
    check(first.verified_local_discovery(true), "local discovery accepted")
    check(not first.storage_error and bridge.writes == 1, "pre-consent discovery saved")
    var restored := make_service(bridge)
    check(restored.state == Service.State.AWAITING_CONSENT, "pre-consent restart recovery")
    check(not restored.take_reveal() and not restored.verified_local_discovery(true), "restart neither advertises nor duplicates")
    var identity := {"ok":true,"verified_signature":true,"display_name":"FICTIONAL PLAYER","identity_token":JSON.stringify({"team_player_id":"fictional-team","game_player_id":"fictional-game-player","public_key_url":"https://static.gc.apple.com/key","signature":"fictional-signature","salt":"fictional-salt","timestamp":123456})}
    var discovery := {"idempotency_key":"fictional-idempotency","egg_id":"fictional-egg","evidence":"fictional-evidence"}
    bridge.fail_write = true
    check(restored.choose_publication(false, identity, "com.flinsvault.fictional", discovery), "choice retained in memory on storage failure")
    check(restored.storage_error and restored.begin_submission(0).is_empty(), "unsaved choice cannot submit")
    bridge.fail_write = false
    check(restored.retry_persistence(), "storage retry saves the same choice")
    check(not JSON.stringify(bridge.records).contains("fictional-signature"), "no reusable proof written")
    var pending := make_service(bridge)
    check(pending.state == Service.State.PENDING_SUBMISSION and pending.website_request_count == 0, "pending restart stays offline")
    check(pending.begin_submission(0).is_empty(), "restart requires fresh identity")
    check(pending.refresh_pending_identity(identity, "com.flinsvault.fictional"), "same account refresh")
    check(pending.begin_submission(0).get("idempotency_key") == "fictional-idempotency", "stable restart idempotency")
    var response := {"discovery_id":"fictional-discovery","public_reference":"fictional-reference","public_secret_code":"fictional-code","discovered_at":"2026-01-01T00:00:00Z","overall_rank":1,"game_rank":1,"first_for_game":true,"privacy_status":"ANONYMOUS","public_identity_source":"anonymous","public_player":"Anonymous","golden_egg_hunt_url":"https://theflinsappvaultllc.com/golden-eggs","public_discovery_url":"https://theflinsappvaultllc.com/golden-eggs/discovery/fictional-reference"}
    check(pending.accept_server_result(response), "authoritative fixture saved")
    var completed := make_service(bridge)
    check(completed.state == Service.State.VERIFIED and not completed.verified_local_discovery(true), "completed restart suppresses duplicate discovery")
    check(completed.server_result().get("public_player") == "Anonymous", "NO retained after restart")
    bridge.fail_read = true
    var unreadable := make_service(bridge)
    var writes_before := bridge.writes
    unreadable.verified_local_discovery(true)
    check(unreadable.storage_error and bridge.writes == writes_before, "read failure never overwrites existing discovery")
    var local_bridge := Bridge.new()
    var local := make_service(local_bridge)
    check(not local.choose_local_only(), "local-only requires discovery")
    local.verified_local_discovery(true)
    check(local.choose_local_only(), "explicit local-only accepted")
    check(local.begin_submission(0).is_empty() and local.website_request_count == 0, "local-only never submits")
    var local_restart := make_service(local_bridge)
    check(local_restart.state == Service.State.LOCAL_ONLY, "local-only survives restart")
    check(local_restart.begin_submission(100000).is_empty() and not local_restart.take_reveal(), "local-only restart never retries or advertises")
    print("GOLDEN_EGG_PERSISTENCE checks=%d failures=%d" % [checks, failures.size()])
    for failure: String in failures:
        push_error(failure)
    quit(0 if failures.is_empty() else 1)

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures.append(message)
