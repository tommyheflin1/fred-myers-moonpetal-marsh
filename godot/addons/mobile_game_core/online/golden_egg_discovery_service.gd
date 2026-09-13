class_name GoldenEggDiscoveryService
extends RefCounted

const GoldenEggContract = preload("res://addons/mobile_game_core/online/golden_egg_web_contract.gd")

enum State { DORMANT, AWAITING_CONSENT, PENDING_SUBMISSION, VERIFIED }

var state: State = State.DORMANT
var website_request_count := 0
var _contract: RefCounted
var _pending: Dictionary = {}
var _result: Dictionary = {}

func configure(game_id: String, egg_id: String) -> bool:
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
    return true

func choose_publication(public_name_consent: bool, platform_result: Dictionary, bundle_id: String, discovery: Dictionary) -> bool:
    if state != State.AWAITING_CONSENT or _contract == null:
        return false
    var identity: Dictionary = _contract.identity_exchange_body(platform_result, bundle_id, public_name_consent)
    if identity.is_empty():
        return false
    var idempotency_key := str(discovery.get("idempotency_key", ""))
    if idempotency_key.is_empty():
        return false
    _pending = {
        "identity": identity,
        "discovery": discovery.duplicate(true),
        "public_name_consent": public_name_consent,
        "idempotency_key": idempotency_key,
    }
    state = State.PENDING_SUBMISSION
    return true

func pending_snapshot() -> Dictionary:
    return _pending.duplicate(true)

func restore_pending(snapshot: Dictionary) -> bool:
    if snapshot.is_empty() or str(snapshot.get("idempotency_key", "")).is_empty():
        return false
    _pending = snapshot.duplicate(true)
    state = State.PENDING_SUBMISSION
    return true

func begin_submission() -> Dictionary:
    if state != State.PENDING_SUBMISSION or _pending.is_empty():
        return {}
    website_request_count += 1
    return _pending.duplicate(true)

func submission_failed() -> void:
    # Keep the same durable idempotency key and remain playable/pending.
    if state == State.PENDING_SUBMISSION:
        state = State.PENDING_SUBMISSION

func accept_server_result(result: Dictionary) -> bool:
    if state != State.PENDING_SUBMISSION or not _contract.validate_discovery_response(result):
        return false
    _result = _contract.public_snapshot(result)
    _pending.clear()
    state = State.VERIFIED
    return true

func server_result() -> Dictionary:
    return _result.duplicate(true)
