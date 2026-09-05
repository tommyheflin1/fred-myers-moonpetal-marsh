class_name GoldenEggNetworkBridge
extends Node

signal operation_completed(operation: String, result: Dictionary)

const ALLOWED_ORIGIN := "https://theflinsappvaultllc.com"
const CONNECT_TIMEOUT_MSEC := 8000
const RESPONSE_TIMEOUT_MSEC := 12000
const MAX_RESPONSE_BYTES := 65536

var worker := Thread.new()
var active_operation := ""


func is_busy() -> bool:
    return not active_operation.is_empty()


func start_submit(service: RefCounted, evidence: String) -> bool:
    return _start("submit", service, evidence)


func start_retry(service: RefCounted) -> bool:
    return _start("retry", service, "")


func start_privacy(service: RefCounted, make_public: bool, display_name: String) -> bool:
    return _start("privacy_public" if make_public else "privacy_anonymous", service, "")


func _start(operation: String, service: RefCounted, argument: String) -> bool:
    if is_busy():
        return false
    active_operation = operation
    worker = Thread.new()
    var error := worker.start(_run_operation.bind(operation, service, argument))
    if error != OK:
        active_operation = ""
        return false
    set_process(true)
    return true


func _process(_delta: float) -> void:
    if not is_busy() or worker.is_alive():
        return
    var completed_operation := active_operation
    var result_value: Variant = worker.wait_to_finish()
    active_operation = ""
    set_process(false)
    var result: Dictionary = result_value if result_value is Dictionary else {
        "success": false,
        "pending": true,
        "error": "NETWORK_OPERATION_FAILED",
    }
    operation_completed.emit(completed_operation, result)


func _exit_tree() -> void:
    if is_busy() and worker.is_started():
        worker.wait_to_finish()


func _run_operation(operation: String, service: RefCounted, argument: String) -> Dictionary:
    match operation:
        "submit":
            return service.submit_discovery(argument)
        "retry":
            return service.retry_pending_discovery()
        "privacy_public":
            return service.submit_privacy_choice(true)
        "privacy_anonymous":
            return service.submit_privacy_choice(false)
        _:
            return {"success": false, "error": "UNKNOWN_NETWORK_OPERATION"}


func request_json(method: String, url: String, headers: Dictionary, body: String) -> Dictionary:
    if not (url.begins_with("%s/api/golden-eggs/" % ALLOWED_ORIGIN) or url == "%s/api/game-center/identity/exchange" % ALLOWED_ORIGIN):
        return _failure("REQUEST_ORIGIN_REJECTED")
    var method_id := _method_id(method)
    if method_id < 0:
        return _failure("REQUEST_METHOD_REJECTED")
    var client := HTTPClient.new()
    var error := client.connect_to_host("theflinsappvaultllc.com", 443, TLSOptions.client())
    if error != OK:
        return _failure("NETWORK_CONNECT_FAILED")
    var deadline := Time.get_ticks_msec() + CONNECT_TIMEOUT_MSEC
    while client.get_status() in [HTTPClient.STATUS_RESOLVING, HTTPClient.STATUS_CONNECTING]:
        client.poll()
        if Time.get_ticks_msec() >= deadline:
            client.close()
            return _failure("NETWORK_CONNECT_TIMEOUT")
        OS.delay_msec(10)
    if client.get_status() != HTTPClient.STATUS_CONNECTED:
        client.close()
        return _failure("NETWORK_CONNECT_FAILED")
    var request_headers := PackedStringArray()
    for header_key: Variant in headers.keys():
        request_headers.append("%s: %s" % [str(header_key), str(headers[header_key])])
    var request_path := url.trim_prefix(ALLOWED_ORIGIN)
    error = client.request(method_id, request_path, request_headers, body)
    if error != OK:
        client.close()
        return _failure("NETWORK_REQUEST_FAILED")
    deadline = Time.get_ticks_msec() + RESPONSE_TIMEOUT_MSEC
    while client.get_status() == HTTPClient.STATUS_REQUESTING:
        client.poll()
        if Time.get_ticks_msec() >= deadline:
            client.close()
            return _failure("NETWORK_RESPONSE_TIMEOUT")
        OS.delay_msec(10)
    if not client.has_response():
        client.close()
        return _failure("NETWORK_RESPONSE_MISSING")
    var response_code := client.get_response_code()
    var response_bytes := PackedByteArray()
    deadline = Time.get_ticks_msec() + RESPONSE_TIMEOUT_MSEC
    while client.get_status() == HTTPClient.STATUS_BODY:
        client.poll()
        var chunk := client.read_response_body_chunk()
        if not chunk.is_empty():
            response_bytes.append_array(chunk)
            if response_bytes.size() > MAX_RESPONSE_BYTES:
                client.close()
                return _failure("NETWORK_RESPONSE_TOO_LARGE")
        if Time.get_ticks_msec() >= deadline:
            client.close()
            return _failure("NETWORK_BODY_TIMEOUT")
        OS.delay_msec(5)
    client.close()
    var parsed_body: Variant = JSON.parse_string(response_bytes.get_string_from_utf8())
    if parsed_body is not Dictionary:
        return {"status": response_code, "body": {"success": false, "error": "BACKEND_RESPONSE_INVALID"}}
    return {"status": response_code, "body": parsed_body}


func _method_id(method: String) -> int:
    match method.to_upper():
        "GET":
            return HTTPClient.METHOD_GET
        "POST":
            return HTTPClient.METHOD_POST
        "PATCH":
            return HTTPClient.METHOD_PATCH
        _:
            return -1


func _failure(reason: String) -> Dictionary:
    return {"status": 0, "body": {"success": false, "pending": true, "error": reason}}
