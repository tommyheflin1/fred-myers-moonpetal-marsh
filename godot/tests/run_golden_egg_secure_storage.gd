extends SceneTree

const Store := preload("res://scripts/golden_egg_local_store.gd")
var failures: int = 0
var checks: int = 0

class FakeKeychain extends RefCounted:
    var data: Dictionary = {}
    var reject_writes: bool = false
    var corrupt_readback: bool = false

    func flins_keychain_read(key: String) -> Dictionary:
        return {"ok": true, "found": data.has(key), "value": "corrupt" if corrupt_readback else data.get(key, "")}

    func flins_keychain_write(key: String, value: String) -> int:
        if reject_writes:
            return -1
        data[key] = value
        return 0

    func flins_keychain_erase(key: String) -> int:
        data.erase(key)
        return 0

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error(label)

func legacy(value: String) -> void:
    var file := FileAccess.open(Store.STORE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify({"golden_egg.fixture": value}))
    file.close()

func _initialize() -> void:
    # The runner must supply isolated APPDATA/LOCALAPPDATA; fixtures are fictional.
    legacy("fictional-old")
    var unavailable := Store.new(RefCounted.new(), "iOS")
    check(unavailable.get_secret("golden_egg.fixture").is_empty(), "iOS must not read plaintext when native storage is missing")
    check(not unavailable.set_secret("golden_egg.fixture", "new"), "iOS must not write plaintext")
    check(FileAccess.file_exists(Store.STORE_PATH), "Unavailable bridge must preserve pending migration")
    var backend := FakeKeychain.new()
    backend.reject_writes = true
    var failed := Store.new(backend, "iOS")
    check(failed.get_secret("golden_egg.fixture").is_empty(), "Failed migration must not use plaintext")
    check(FileAccess.file_exists(Store.STORE_PATH), "Failed migration must remain retryable")
    backend.reject_writes = false
    backend.corrupt_readback = true
    var corrupt := Store.new(backend, "iOS")
    check(FileAccess.file_exists(Store.STORE_PATH), "Readback mismatch must preserve legacy file")
    backend.data.clear()
    backend.corrupt_readback = false
    var secured := Store.new(backend, "iOS")
    check(secured.get_secret("golden_egg.fixture") == "fictional-old", "Migration must preserve credential value")
    check(not FileAccess.file_exists(Store.STORE_PATH), "Verified migration must remove plaintext credential file")
    check(secured.set_secret("golden_egg.fixture", "fictional-new"), "Keychain write")
    check(not FileAccess.file_exists(Store.STORE_PATH), "Secure writes must not recreate plaintext")
    legacy("fictional-stale")
    var newer := Store.new(backend, "iOS")
    check(newer.get_secret("golden_egg.fixture") == "fictional-new", "Stale legacy file must not overwrite newer Keychain value")
    check(newer.erase_secret("golden_egg.fixture"), "Keychain erase")
    var relaunched := Store.new(backend, "iOS")
    check(relaunched.get_secret("golden_egg.fixture").is_empty(), "Erased credential must not reappear after relaunch")
    check(not relaunched.set_secret("other.fixture", "x"), "Reject foreign key")
    print("FRED_SECURE_STORAGE checks=%d failures=%d" % [checks, failures])
    quit(1 if failures else 0)
