# Class animation clips (ART.md §7)

Looping videos played at certain moments in place of the static class art.
Organized **per class, then per moment**:

    ClassMotion/
      Wanderer/
        info/       <- full-screen behind the ⓘ class detail
        focus/      <- scrimmed, behind a running focus block
        ceremony/   <- the first-class award
        levelup/    <- a promotion
      Ascetic/
        info/
        ...

Drop a clip (`.mov` or `.mp4`, **any filename** — the first one in the folder
wins) into the matching folder. No clip → the static `ClassArt` image shows.
Reduce Motion → always the static image.

This folder is bundled as a **folder reference**, so the structure is
preserved and adding a clip needs only a rebuild — no `xcodegen generate`.
Keep clips short, **muted**, and seamlessly looping (first frame ≈ last).
