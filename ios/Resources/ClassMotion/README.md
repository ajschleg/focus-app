# Class animation clips (ART.md §7)

Looping videos played at certain moments in place of the static class art.

**Naming:** `<ClassName>-<moment>.mov` (or `.mp4`), e.g.

    Wanderer-info.mov     # full-screen behind the ⓘ class detail
    Wanderer-focus.mov    # scrimmed, behind a running focus block

**Moments:** `info`, `focus`, `ceremony`, `levelup`. A bare `<ClassName>.mov`
is the ambient fallback used when a moment-specific clip is absent. No clip →
the static `ClassArt` image shows. Reduce Motion → always the static image.

Keep them short, **muted**, seamlessly looping, and small — they stream via
`AVPlayer`, one plays at a time, and the player is released off-screen
(`LoopingVideoView`). After adding files here, run `xcodegen generate` so
they're bundled.
