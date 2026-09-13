class_name UpdatePolicySignatureVerifier
extends RefCounted

var public_key: CryptoKey
var trusted_key_id := ""

func configure(public_key_pem: String, configured_key_id: String) -> bool:
    if public_key_pem.strip_edges().is_empty() or configured_key_id.strip_edges().is_empty():
        return false
    var candidate := CryptoKey.new()
    if candidate.load_from_string(public_key_pem, true) != OK or not candidate.is_public_only():
        return false
    public_key = candidate
    trusted_key_id = configured_key_id.strip_edges()
    return true

func verify(payload_text: String, signature_base64: String, key_id: String) -> bool:
    if public_key == null or key_id != trusted_key_id or payload_text.is_empty() or not _valid_base64(signature_base64):
        return false
    var signature := Marshalls.base64_to_raw(signature_base64)
    if signature.is_empty():
        return false
    return Crypto.new().verify(HashingContext.HASH_SHA256, payload_text.sha256_buffer(), signature, public_key)

func _valid_base64(value: String) -> bool:
    if value.is_empty() or value.length() % 4 != 0:
        return false
    var padding_started := false
    for character: String in value:
        if character == "=":
            padding_started = true
        elif padding_started or not ((character >= "A" and character <= "Z") or (character >= "a" and character <= "z") or (character >= "0" and character <= "9") or character in ["+", "/"]):
            return false
    return value.count("=") <= 2
