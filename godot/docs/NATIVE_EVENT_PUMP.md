# Native callback responsiveness

TurboRack is the behavioral reference for asynchronous Game Center sign-in,
native leaderboard presentation and continued menu interaction. Do not copy its
branding or IDs. Inspect the consumer's actual bridge and UI before migrating.

Native queues must use `online/native_event_pump.gd`: process at most 32 events
per frame, preserve remaining callbacks, and continue polling after authentication.
A queue flood must not prevent the next UI frame or authentication timeout.
The helper does not create a worker thread: each native pop/handler must itself
be nonblocking. Device profiling is still required.

Regression: Core `tests/run_native_event_pump.gd` supplies 100 fictional events;
one pass consumes 32 and subsequent passes consume the rest without loss.
Fred additionally tests reconnect identity clearing and missing-player rejection.
Do not retain a previous display name while resolving a new account.

This is not proof of the cause of a reported native freeze. Preserve native
logs, inspect bridge callbacks, and test signed iPhone behavior independently.
Existing apps adopt explicitly; TurboRack and released Core pins are not changed
automatically. Future template consumers include this helper by default.
