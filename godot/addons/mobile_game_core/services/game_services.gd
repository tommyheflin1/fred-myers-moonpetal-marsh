extends Node

signal service_registered(name: StringName)
signal lifecycle_changed(state: StringName)

var _services: Dictionary = {}

func register_service(name: StringName, service: Object) -> void:
    assert(not name.is_empty(), "Service name cannot be empty")
    assert(service != null, "Service cannot be null")
    _services[name] = service
    service_registered.emit(name)

func resolve(name: StringName) -> Object:
    return _services.get(name)

func has_service(name: StringName) -> bool:
    return _services.has(name)

func unregister_service(name: StringName) -> void:
    _services.erase(name)

func notify_lifecycle(state: StringName) -> void:
    lifecycle_changed.emit(state)
    if state in [&"paused", &"background", &"shutdown"]:
        var save_service: Object = resolve(&"save")
        if save_service != null and save_service.has_method("flush"):
            save_service.call("flush")

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED: notify_lifecycle(&"paused")
    elif what == NOTIFICATION_APPLICATION_RESUMED: notify_lifecycle(&"resumed")
    elif what == NOTIFICATION_WM_CLOSE_REQUEST: notify_lifecycle(&"shutdown")

