---
name: mandatory-app-update
description: Implement and operate the Flins server-controlled minimum-build gate for iOS. Use for force-update behavior, update blocking screens, policy activation, App Store availability checks, or rollback and outage recovery.
---

# Mandatory app update

Apple does not guarantee an update is installed: users may disable automatic downloads. Enforce the requirement in the app by checking a signed server policy before game entry and blocking any build below `minimum_supported_build`.

Read [activation-and-recovery.md](references/activation-and-recovery.md) before changing a live minimum build. Use `UpdatePolicyService`; do not create an app-specific force-update protocol.

## Product contract

- Check the policy before loading gameplay and whenever the app returns to the foreground.
- Bind the signed response to the exact bundle ID and platform, with issue and expiry times. Reject unsigned, expired, malformed, or wrong-app responses.
- Fail closed: without a valid policy, show a service-unavailable screen and do not enter gameplay.
- Below the minimum, show only the approved update explanation, **Open App Store**, and **Retry**. Do not expose a skip, offline, or continue path.
- Use an `https://apps.apple.com/` product URL from app-owned configuration.
- Never activate a higher minimum until the exact replacement build is verified publicly downloadable for every supported storefront and device class.

Changing a live policy is a protected production action requiring explicit owner approval. Apple submission, public release, and minimum-build activation are three separate approvals and evidence gates.

Test with fictional identities: current build allowed; older build blocked; invalid, expired, wrong-bundle, and unavailable policy blocked; App Store link correct; foreground recheck works; lowering the minimum restores access.
