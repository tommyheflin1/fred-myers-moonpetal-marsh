# Settled owner decision: discovery-only website contact

Owner instruction: "DONT HAVE APPS ASK ME QUESTIONS THAT IS KNOWN TO ALRADY BE
ANSWERED; THE EGG HUNT IS THE ONLY TIME THE APP SHOULD TOUCH THE WEBSITE AND THATS
ONLY WHEN THE GOLDEN EGG IS FOUND".

This is the shared default for existing and future participating games. Do not ask
the owner again whether normal gameplay should contact the company website.

- No app-initiated company-website request during launch, normal menus, gameplay,
  foreground resume, Game Center authentication, native leaderboards or achievements.
- No company-website availability, policy, campaign, leaderboard or minimum-build
  polling on those paths. Older optional website-update behavior must be identified
  as migration work, not silently retained as an exception to this newer instruction.
- Verified local Golden Egg discovery is the only activation event. Publication
  still requires the player's explicit Public or Anonymous choice; Don't Post stays
  local and sends nothing. Do not mistake owner approval for player consent.
- Failure or pending recovery must never block normal play or turn normal startup
  into a website request. Preserve secure state, original identity binding and
  idempotency; keep recovery limited to that discovered egg's authorized flow.
- Platform Game Center services are distinct from the company website. Preserve
  native Game Center functionality and existing identifiers.

Before asking an owner question, check the task history and existing exact decision
records. Reuse approval for the same scope instead of asking again. If something
materially new needs approval, identify precisely what changed; do not repackage
already approved architecture as a new choice. The Fred task has recorded explicit
approval of the September 12 three-choice/discovery-only privacy revision.
This does not waive unrelated signing, security, data, rights or release gates.

This record establishes required behavior; it does not claim every shipped binary
has been migrated or that a website deployment or Apple upload occurred.
