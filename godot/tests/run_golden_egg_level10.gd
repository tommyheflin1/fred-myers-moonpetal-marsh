extends SceneTree

const Main = preload("res://scripts/main.gd")
const RunState = preload("res://scripts/golden_egg_run_state.gd")
const DiscoveryStore = preload("res://scripts/golden_egg_discovery_store.gd")
const GoldenClient = preload("res://scripts/golden_egg_client.gd")

const GUARD := "user://golden_egg_level10_guard.json"
const DISCOVERY := "user://golden_egg_level10_discovery.json"

var passed := 0
var failed := 0

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		push_error("FAIL " + label)

func clean_files() -> void:
	for path: String in [GUARD, GUARD.trim_suffix(".json") + ".tmp.json", DISCOVERY, DISCOVERY.trim_suffix(".json") + ".tmp.json", "user://headless_fred_golden_egg_guard.json", "user://headless_fred_golden_egg_guard.tmp.json", "user://headless_fred_golden_egg_discovery.json", "user://headless_fred_golden_egg_discovery.tmp.json"]:
		var absolute := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(absolute)

func _init() -> void:
	_run.call_deferred()

func _advance_to_ten(state: RefCounted) -> void:
	state.begin_level_one("00000000-0000-4000-8000-000000000010")
	for level in range(1, 10):
		state.advance_level(level, level + 1)

func _corners(state: RefCounted) -> void:
	for rect: Rect2 in RunState.CORNER_RECTS:
		state.observe_position(10, rect.get_center(), true)
		state.observe_position(10, Vector2(640,360), true)

func _qualify(state: RefCounted) -> void:
	_advance_to_ten(state)
	_corners(state)
	state.note_surface_complete(10)
	for jump in RunState.REQUIRED_JUMPS:
		state.note_valid_surface_jump(10)

func _run() -> void:
	clean_files()
	check(RunState.GAME_ID == "fred-myers", "Fred uses its own stable Golden Egg game ID")
	check(RunState.EGG_ID == "moonpetal-golden-egg", "Fred uses its own Moonpetal egg ID")
	check(RunState.GAME_ID != "snake-reactor", "Fred never reuses Snake Reactor's game identity")
	check(RunState.CORNER_RECTS.size() == 4, "exactly four tight Level 10 corner zones exist")
	for index in RunState.CORNER_RECTS.size():
		var rect: Rect2 = RunState.CORNER_RECTS[index]
		check(rect.size.x <= 150.0 and rect.size.y <= 125.0, "corner %d is bounded and intentional" % index)
		check(rect.position.x >= 55.0 and rect.position.y >= 105.0 and rect.end.x <= 1225.0 and rect.end.y <= 665.0, "corner %d stays inside the playfield" % index)

	var direct := RunState.new(GUARD)
	check(not direct.try_predator_event(10), "direct Level 10 entry cannot reveal the egg")
	check(not direct.eligible_for_reveal(), "missing Level 1 history is ineligible")
	direct.begin_level_one("run-direct")
	direct.advance_level(1,10)
	check(direct.phase == RunState.Phase.INVALID, "level skipping permanently invalidates the run")
	check(not direct.try_predator_event(10), "a skipped run cannot be revived by predator contact")

	var ordered := RunState.new(GUARD)
	_advance_to_ten(ordered)
	check(ordered.highest_level == 10 and ordered.phase == RunState.Phase.CORNERS, "sequential Levels 1 through 10 unlock the hidden attempt")
	for index in RunState.CORNER_RECTS.size():
		ordered.observe_position(10, RunState.CORNER_RECTS[index].get_center(), true)
		check(ordered.next_corner == index + 1, "ordered underwater corner %d advances once" % (index + 1))
		ordered.observe_position(10, RunState.CORNER_RECTS[index].get_center(), true)
		check(ordered.next_corner == index + 1, "remaining in corner %d cannot double count" % (index + 1))
		ordered.observe_position(10, Vector2(640,360), true)
	check(ordered.phase == RunState.Phase.WAIT_SURFACE, "four ordered underwater corners require surfacing next")
	ordered.note_surface_complete(10)
	check(ordered.phase == RunState.Phase.JUMPS, "completed surfacing opens the exact jump sequence")
	for jump in range(1,5):
		ordered.note_valid_surface_jump(10)
		check(ordered.surface_jumps == jump, "valid surface jump %d counts exactly once" % jump)
	check(ordered.phase == RunState.Phase.ARMED and ordered.eligible_for_reveal(), "exactly four surface jumps arm the qualifying predator event")
	check(not ordered.try_predator_event(9), "predator contact outside Level 10 cannot reveal")
	check(ordered.try_predator_event(10), "qualifying Level 10 predator contact reveals instead of killing Fred")
	check(ordered.phase == RunState.Phase.REVEALED, "qualifying event becomes a one-way revealed state")
	check(not ordered.try_predator_event(10), "repeated predator contact cannot duplicate the discovery")

	var early_predator := RunState.new(GUARD)
	_advance_to_ten(early_predator)
	_corners(early_predator)
	early_predator.note_surface_complete(10)
	for jump in 3: early_predator.note_valid_surface_jump(10)
	check(not early_predator.try_predator_event(10), "three jumps remain an ordinary predator death path")
	early_predator.note_valid_surface_jump(10)
	early_predator.note_valid_surface_jump(10)
	check(early_predator.phase == RunState.Phase.INVALID, "a fifth jump silently invalidates the attempt")

	for wrong_first in [1,2,3]:
		var wrong := RunState.new(GUARD)
		_advance_to_ten(wrong)
		wrong.observe_position(10, RunState.CORNER_RECTS[wrong_first].get_center(), true)
		check(wrong.phase == RunState.Phase.INVALID, "wrong first corner %d fails closed" % wrong_first)
		check(not wrong.try_predator_event(10), "wrong corner %d cannot reveal later" % wrong_first)
	var surfaced_early := RunState.new(GUARD)
	_advance_to_ten(surfaced_early)
	surfaced_early.observe_position(10, RunState.CORNER_RECTS[0].get_center(), true)
	surfaced_early.note_surface_complete(10)
	check(surfaced_early.phase == RunState.Phase.INVALID, "surfacing after a partial corner sequence invalidates silently")
	var jumped_early := RunState.new(GUARD)
	_advance_to_ten(jumped_early)
	jumped_early.note_valid_surface_jump(10)
	check(jumped_early.phase == RunState.Phase.INVALID, "jumping before the corner and surface sequence invalidates")
	var redive := RunState.new(GUARD)
	_advance_to_ten(redive); _corners(redive); redive.note_surface_complete(10); redive.note_valid_surface_jump(10); redive.note_dive_after_surface(10)
	check(redive.phase == RunState.Phase.INVALID, "diving again after the required surface transition invalidates")

	for death_level in [1,5,9,10]:
		var dead := RunState.new(GUARD)
		dead.begin_level_one("death-%d" % death_level)
		for level in range(1,death_level): dead.advance_level(level,level+1)
		dead.note_death("predator")
		check(not dead.deathless and dead.phase == RunState.Phase.INVALID, "death on Level %d permanently invalidates the run" % death_level)
		var restored := RunState.new(GUARD)
		check(not restored.deathless and restored.phase == RunState.Phase.INVALID, "reload cannot roll back Level %d death" % death_level)

	var recoverable := RunState.new(GUARD)
	_advance_to_ten(recoverable)
	recoverable.observe_position(10, RunState.CORNER_RECTS[0].get_center(), true)
	var recovered := RunState.new(GUARD)
	check(recovered.highest_level == 10 and recovered.next_corner == 1 and recovered.deathless, "crash recovery preserves active run progress")
	recovered.note_death("hazard")
	var old_save_attempt := AdventureSession.new()
	check(not old_save_attempt.to_save().has("golden_egg"), "ordinary fred_save v1 cannot contain or roll back Golden Egg guard state")
	var still_dead := RunState.new(GUARD)
	check(still_dead.phase == RunState.Phase.INVALID, "loading ordinary game state cannot resurrect eligibility")

	var store := DiscoveryStore.new(DISCOVERY)
	var valid_state := RunState.new(GUARD)
	_qualify(valid_state)
	var idem := "11111111-2222-4333-8444-555555555555"
	var staged: Dictionary = store.stage_pending(valid_state.evidence(), idem)
	check(bool(staged.ok), "qualifying evidence stages an offline-safe pending discovery")
	var pending: Dictionary = store.load_record()
	check(bool(pending.ok) and str(pending.record.status) == "pending", "pending discovery survives relaunch")
	check(str(pending.record.idempotency_key) == idem, "retry preserves one stable idempotency key")
	check(str(pending.record.privacy) == "anonymous", "privacy defaults to anonymous")
	check(not bool(store.stage_pending({"game_id":"snake-reactor","egg_id":"golden-egg"},idem).ok), "Snake Reactor identity is rejected by Fred's discovery store")
	check(not bool(store.accept_server_result({"server_rank":1}).ok), "client rejects incomplete server results")
	var accepted := store.accept_server_result({"discovery_id":"d1","public_ref":"p1","server_rank":7,"server_time":"server-owned","secret_code":"FM-TEST"})
	check(bool(accepted.ok) and str(accepted.record.status) == "accepted", "only a complete server result can become accepted")
	check(int(accepted.record.server.server_rank) == 7 and str(accepted.record.server.server_time) == "server-owned", "rank and time come only from the server result")
	check(bool(store.set_privacy("public","Young Marsh Hero").ok), "explicit public-name consent is stored")
	check(str(store.load_record().record.display_name) == "Young Marsh Hero", "consented display name is bounded and recoverable")
	check(bool(store.set_privacy("anonymous").ok) and str(store.load_record().record.display_name).is_empty(), "anonymous choice removes the public display name")
	check(not bool(store.set_privacy("friends-only").ok), "unsupported privacy modes fail closed")

	var client := GoldenClient.new()
	var uuid_a := "aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee"
	var uuid_b := "11111111-2222-4333-8444-555555555555"
	check(not bool(client.discovery_request(valid_state.evidence(),"3","local-golden-egg",uuid_a,1800000000,uuid_b).ok), "network request fails closed without a platform secure signer")
	var key := PackedByteArray()
	key.resize(32)
	key.fill(7)
	check(not client.configure_ephemeral_signer(PackedByteArray([1,2,3])), "short signing material is rejected")
	check(client.configure_ephemeral_signer(key,"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"), "ephemeral platform signing material can be injected without serialization")
	var request: Dictionary = client.discovery_request(valid_state.evidence(),"3","local-golden-egg",uuid_a,1800000000,uuid_b)
	check(bool(request.ok) and str(request.url) == "https://theflinsappvaultllc.com/api/golden-eggs/discoveries", "discovery uses the canonical App Vault endpoint")
	check(str(request.body).contains('"egg_id":"moonpetal-golden-egg"') and str(request.body).contains('"egg_version":"1"'), "discovery body uses Fred's exact registered egg contract")
	check(str(request.body).contains('"build_version":"local-golden-egg"'), "build identity is included in verification")
	var headers := "\n".join(Array(request.headers))
	check(headers.contains("X-Golden-Egg-Game-Id: fred-myers"), "signed request carries Fred's separate game ID")
	check(headers.contains("Idempotency-Key: " + uuid_a), "signed retry uses the stored idempotency key")
	check(headers.contains("Authorization: Bearer "), "discovery requires player-bound bearer authentication")
	check(headers.contains("X-Golden-Egg-Signature: v1=") and not headers.contains("07070707"), "HMAC signature is present without exposing signing material")
	var retry: Dictionary = client.discovery_request(valid_state.evidence(),"3","local-golden-egg",uuid_a,1800000001,"22222222-3333-4444-8555-666666666666")
	check(bool(retry.ok) and str(retry.body) == str(request.body), "retry keeps the exact logical payload")
	check(str(retry.headers) != str(request.headers), "retry refreshes timestamp, nonce, and HMAC signature")
	check(not bool(client.build_request("GET","/api/golden-eggs/leaderboard",{},uuid_a,1800000000,uuid_b,false).ok), "signer refuses unapproved method and endpoint shapes")
	check(not bool(client.privacy_request("../other-player","PUBLIC","Hero",uuid_a,1800000000,uuid_b).ok), "privacy path traversal fails closed")
	var server_result := client.validate_server_discovery({"success":true,"discovery_id":"d_1","public_reference":"GE_ref","overall_rank":12,"discovered_at":"2030-01-01T00:00:00.000Z","public_secret_code":"FM-ABCD-EFGH"})
	check(bool(server_result.ok) and int(server_result.server_rank) == 12, "validated server response supplies authoritative rank")
	check(str(server_result.server_time) == "2030-01-01T00:00:00.000Z", "validated server response supplies authoritative time")
	check(not bool(client.validate_server_discovery({"success":true,"overall_rank":1}).ok), "incomplete server response is never accepted")
	client.clear_credentials()
	check(not client.is_configured(), "ephemeral credentials are zeroed and cleared on demand")

	var perf := RunState.new(GUARD)
	_advance_to_ten(perf)
	var start_ms := Time.get_ticks_msec()
	for index in 10000:
		perf.observe_position(10, Vector2(640 + float(index % 7),360), true)
	var elapsed := Time.get_ticks_msec() - start_ms
	check(perf.next_corner == 0 and perf.phase == RunState.Phase.CORNERS, "10,000 ordinary movement observations cannot advance the secret")
	check(elapsed < 1000, "10,000 state observations stay within the local performance budget")

	var game: Node2D = Main.new()
	game.audio_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var chime: AudioStreamWAV = game._build_golden_chime()
	check(chime.mix_rate == 22050 and chime.data.size() == int(22050.0*0.92)*2, "Moonpetal reveal chime is bounded, local, and deterministic")
	check(not chime.loop_mode, "celebratory chime plays once and cannot overlap as looping music")
	game.golden_run = RunState.new(GUARD)
	game.golden_discovery = DiscoveryStore.new(DISCOVERY)
	_qualify(game.golden_run)
	game.level_number = 10
	game.screen = Main.Screen.PLAYING
	game.session.health = 3
	check(game._try_golden_egg_predator_event(), "main gameplay intercepts a fully qualified predator event")
	check(game.screen == Main.Screen.GOLDEN_EGG and game.session.health == 3, "Golden Egg reveal replaces death without consuming a life")
	check(not game._try_golden_egg_predator_event(), "main gameplay cannot submit the same discovery twice")
	check(game._golden_egg_hunt_url() == "https://theflinsappvaultllc.com/golden-eggs", "reveal exposes only the canonical HTTPS Golden Egg Hunt link")
	check(not Main.GOLDEN_EGG_PRIVATE_RECT.intersects(Main.GOLDEN_EGG_HUNT_RECT) and not Main.GOLDEN_EGG_PUBLIC_RECT.intersects(Main.GOLDEN_EGG_HOME_RECT), "reveal privacy and navigation controls do not overlap")
	game._go_home()
	check(game.screen == Main.Screen.TITLE and game.level_number == 1, "Home leaves the reveal and resets ordinary play to Level 1")
	game.queue_free()
	await process_frame
	await process_frame

	clean_files()
	print("RESULT golden_egg_level10_passed=%d golden_egg_level10_failed=%d" % [passed,failed])
	quit(1 if failed else 0)
