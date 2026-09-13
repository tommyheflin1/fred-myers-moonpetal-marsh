extends RefCounted
## Bound native callback work so a replenishing queue cannot starve UI/timeouts.
const MAX_EVENTS_PER_FRAME := 32

static func drain(plugin: Object, handler: Callable) -> int:
    var count := 0
    while count < MAX_EVENTS_PER_FRAME and int(plugin.call("get_pending_event_count")) > 0:
        var event: Variant = plugin.call("pop_pending_event")
        count += 1
        if event is Dictionary:
            handler.call(event)
    return count
