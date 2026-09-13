class_name GoldenEggDiscoveryService
extends RefCounted

const GoldenEggContract = preload("res://addons/mobile_game_core/online/golden_egg_web_contract.gd")
const IMPLEMENTATION_VERSION := "discovery-state-4"

enum State { DORMANT, AWAITING_CONSENT, PENDING_SUBMISSION, VERIFIED, LOCAL_ONLY }

var state: State = State.DORMANT
var website_request_count := 0
var _contract: RefCounted
var _pending: Dictionary = {}
var _result: Dictionary = {}
var _reveal_pending := false
var _in_flight := false
var _deadline_ms := 0
var _retry_at_ms := 0
var _failures := 0
var _fresh_identity_required := false
var _store: RefCounted
var _storage_required := false
var _storage_loaded := false
var _durable := false
var storage_error := false
const REQUEST_TIMEOUT_MS := 30000

func configure(game_id: String, egg_id: String) -> bool:
    if state != State.DORMANT:
        return false
    _contract = GoldenEggContract.new()
    return _contract.configure(game_id, egg_id)

# Launch, menus, ordinary gameplay, Game Center, achievements and native
# leaderboards never call the Golden Egg network client.
func ordinary_activity(_event: String) -> void:
    pass

func verified_local_discovery(discovery_verified: bool) -> bool:
    if not discovery_verified or state != State.DORMANT:
        return false
    state = State.AWAITING_CONSENT
    _reveal_pending = true
    retry_persistence()
    return true

func take_reveal() -> bool:
    if not _reveal_pending:
        return false
    _reveal_pending = false
    return true

func choose_publication(public_name_consent: bool, platform_result: Dictionary, bundle_id: String, discovery: Dictionary) -> bool:
    if state != State.AWAITING_CONSENT or _contract == null:
        return false
    var identity: Dictionary = _contract.identity_exchange_body(platform_result, bundle_id, public_name_consent)
    if identity.is_empty():
        return false
    var idempotency_key := str(discovery.get("idempotency_key", ""))
    if idempotency_key.is_empty() or discovery.get("egg_id") != _contract.egg_id:
        return false
    _pending = {
        "game_id": _contract.game_id,
        "bundle_id": bundle_id,
        "bound_team_player_id": identity.team_player_id,
        "identity": identity,
        "discovery": discovery.duplicate(true),
        "public_name_consent": public_name_consent,
        "idempotency_key": idempotency_key,
    }
    state = State.PENDING_SUBMISSION
    retry_persistence()
    return true

# Local-only is distinct from Anonymous (which intentionally publishes without a name).
# Never reinterpret dismissal as permission, or schedule a retry for this state.
func choose_local_only() -> bool:
    if state != State.AWAITING_CONSENT:
        return false
    _pending.clear()
    _reveal_pending = false
    state = State.LOCAL_ONLY
    retry_persistence()
    return true

func pending_snapshot() -> Dictionary:
    var snapshot := _pending.duplicate(true)
    if not snapshot.is_empty():
        snapshot["identity"] = {}
    return snapshot

func restore_pending(snapshot: Dictionary) -> bool:
    if state != State.DORMANT or _contract == null or not _valid_pending(snapshot):
        return false
    _pending = snapshot.duplicate(true)
    # Restoring durable state never authorizes replay of an old Apple proof.
    _pending["identity"] = {}
    _fresh_identity_required = true
    state = State.PENDING_SUBMISSION
    return true

func refresh_pending_identity(platform_result: Dictionary, bundle_id: String) -> bool:
    if state != State.PENDING_SUBMISSION or _in_flight:
        return false
    var identity: Dictionary = _contract.identity_exchange_body(platform_result, bundle_id, bool(_pending.get("public_name_consent", false)))
    if identity.is_empty() or identity.get("team_player_id") != _pending.get("bound_team_player_id") or bundle_id != _pending.get("bundle_id"):
        return false
    _pending["identity"] = identity
    _fresh_identity_required = false
    return true

func begin_submission(now_ms: int = -1) -> Dictionary:
    if now_ms < 0:
        now_ms = Time.get_ticks_msec()
    poll_timeout(now_ms)
    if state != State.PENDING_SUBMISSION or _pending.is_empty() or _in_flight or _fresh_identity_required or now_ms < _retry_at_ms or (_storage_required and not _durable):
        return {}
    _in_flight = true
    _deadline_ms = now_ms + REQUEST_TIMEOUT_MS
    website_request_count += 1
    return _pending.duplicate(true)

func submission_failed(now_ms: int = -1) -> void:
    if state != State.PENDING_SUBMISSION or not _in_flight:
        return
    if now_ms < 0:
        now_ms = Time.get_ticks_msec()
    _in_flight = false
    _fresh_identity_required = true
    _pending["identity"] = {}
    _retry_at_ms = now_ms + GoldenEggContract.RETRY_SECONDS[mini(_failures, GoldenEggContract.RETRY_SECONDS.size() - 1)] * 1000
    _failures += 1

func poll_timeout(now_ms: int = -1) -> void:
    if now_ms < 0:
        now_ms = Time.get_ticks_msec()
    if _in_flight and now_ms >= _deadline_ms:
        submission_failed(now_ms)

func accept_server_result(result: Dictionary) -> bool:
    if state != State.PENDING_SUBMISSION or not _in_flight or not _contract.validate_discovery_response(result):
        return false
    if bool(_pending.get("public_name_consent", false)) and (result.get("privacy_status") != "PUBLIC" or result.get("public_identity_source") != "game_center_reported"):
        return false
    if not bool(_pending.get("public_name_consent", false)) and (result.get("privacy_status") != "ANONYMOUS" or result.get("public_identity_source") != "anonymous" or str(result.get("public_player", "Anonymous")) != "Anonymous"):
        return false
    _result = _contract.public_snapshot(result)
    _pending.clear()
    state = State.VERIFIED
    _in_flight = false
    retry_persistence()
    return true

func server_result() -> Dictionary:
    return _result.duplicate(true)

func _valid_pending(snapshot: Dictionary) -> bool:
    if not snapshot.get("public_name_consent") is bool or not snapshot.get("discovery") is Dictionary:
        return false
    var discovery: Dictionary = snapshot.discovery
    return not str(snapshot.get("idempotency_key", "")).is_empty() and snapshot.get("idempotency_key") == discovery.get("idempotency_key") and discovery.get("egg_id") == _contract.egg_id and snapshot.get("game_id") == _contract.game_id and not str(snapshot.get("bundle_id", "")).is_empty() and not str(snapshot.get("bound_team_player_id", "")).is_empty()

func attach_store(store: RefCounted) -> bool:
    _storage_required = true
    if state != State.DORMANT or _contract == null or store == null or not store.has_method("load_record") or not store.has_method("save_record"):
        storage_error = true
        return false
    _store = store
    var loaded: Dictionary = _store.load_record()
    if not bool(loaded.get("ok", false)):
        storage_error = true
        return false
    if bool(loaded.get("found", false)) and not _restore_record(loaded.get("record", {})):
        storage_error = true
        return false
    _storage_loaded = true
    _durable = true
    storage_error = false
    return true

func retry_persistence() -> bool:
    if not _storage_required:
        return true
    # Never overwrite an unreadable or foreign record with a new discovery.
    if not _storage_loaded or _store == null:
        storage_error = true
        _durable = false
        return false
    var record := {"schema_version": 1, "game_id": _contract.game_id, "egg_id": _contract.egg_id, "state": int(state), "pending": pending_snapshot(), "result": server_result()}
    _durable = bool(_store.save_record(record))
    storage_error = not _durable
    return _durable

func _restore_record(record: Dictionary) -> bool:
    if record.get("schema_version") != 1 or record.get("game_id") != _contract.game_id or record.get("egg_id") != _contract.egg_id:
        return false
    var saved_state := int(record.get("state", -1))
    match saved_state:
        State.LOCAL_ONLY:
            state = State.LOCAL_ONLY
        State.AWAITING_CONSENT:
            state = State.AWAITING_CONSENT
        State.PENDING_SUBMISSION:
            if not record.get("pending") is Dictionary or not restore_pending(record.pending):
                return false
        State.VERIFIED:
            if not record.get("result") is Dictionary or not _contract.validate_discovery_response(record.result):
                return false
            _result = _contract.public_snapshot(record.result)
            state = State.VERIFIED
        _:
            return false
    # Recovery never creates a main-menu advertisement or an automatic request.
    _reveal_pending = false
    return true
