# Release checklist

- All automated and device tests pass with recorded evidence.
- Privacy inventory, deletion/export, accessibility, support, age rating, and store metadata are owner-reviewed.
- Dependencies and licenses are reviewed; secret scan is clean.
- Android AAB and iOS archive use owner-controlled signing outside Git.
- Game Center / Play Games identifiers match production configuration.
- Mandatory-update policy is signed, scoped to this bundle/platform, expiry-tested, fail-closed, and points to the exact App Store product URL.
- Keep the live minimum compatible until the replacement is publicly downloadable; activation and rollback require separate owner approval and recorded evidence.
- Production upload and release require explicit owner approval.
