# No app notifications

Owner decision, 2026-09-20: all 12 existing and all future games do not use app
notifications. No local/scheduled or push notifications, notification permission
prompts, device-token registration, notification SDKs, app-icon notification badges,
reminder campaigns, notification extensions or notification background modes.
This is settled; do not ask each app owner to reconfirm it.

This does not remove ordinary gameplay feedback, independently supplied Game Center
UI, explicitly requested Golden Egg consent or the separately authorized mandatory
in-app update screen. It does not change Codex task/automation notifications.

`tools/notification_policy.py` runs in the process audit, including the release-ios
entry gate. It rejects known notification APIs, SDK markers, capabilities and enabled
configuration. Matches require review/removal, not a blanket ignore or lock rewrite.
The signed bundle scanner also rejects notification background modes/extensions.

Static scanning is a tripwire, not proof of absence: reflective calls, opaque native
dependencies and platform packaging require app-owned dependency/export review.
Before the next build record exact source and exported entitlement/manifest review;
before App Review verify fresh install, launch, background/resume and gameplay on
device produce no notification permission prompt, scheduling, registration or badge.
Never mark device checks passed from this scanner. Existing archives remain intact;
adopt through each app's normal next-build migration, not concurrent edits by root.
