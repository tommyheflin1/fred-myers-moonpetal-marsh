# Activation and recovery

## Release sequence

1. Ship the replacement with the gate dormant: the live minimum remains compatible with the currently public build.
2. Complete local, archive, upload, Apple processing, TestFlight, physical-device, and App Review gates separately.
3. After explicitly authorized public release, verify the exact version and build is downloadable from its public App Store product page in every supported storefront and on every supported device class.
4. Prefer release-to-all for a mandatory migration. A phased release reaches automatic-update users gradually; do not raise the minimum during a phase unless the replacement is already manually downloadable everywhere in scope and blocking those users was explicitly approved.
5. With separate owner authorization, publish a signed policy that raises `minimum_supported_build`. Record policy digest, activation time, bundle ID, previous minimum, new minimum, and storefront evidence.
6. Confirm an old production build blocks and the replacement enters gameplay. Preserve the evidence without player identifiers.

## Policy and client invariants

- Authenticate transport and verify the response signature independently.
- Include schema version, bundle ID, platform, minimum build, issue time, expiry time, and policy ID in the signed payload.
- Treat build number, not marketing-version text, as the ordering authority.
- The server must never infer authority from a client-supplied `force_update` flag.
- A cached policy is usable only while its signed expiry remains valid. Once missing or expired, fail closed.

## Recovery

Policy service failure can block every player because this product intentionally fails closed. Keep the policy endpoint independently monitored and rollback-capable. Recovery is to restore a valid signed response or lower the minimum through the same authenticated policy channel; never add a hidden bypass. Verify recovery on an affected build and record it. If the App Store replacement is withdrawn or broken, lower the minimum before further rollout when a safe older build remains available.
