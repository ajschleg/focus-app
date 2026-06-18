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

**`info` and `focus` share one clip.** They're the same source visual — the
focus background just scrims it — so author a single clip in `info/` and the
running-block background reuses it. Drop a clip in `focus/` only when you want
a *distinct* one there; otherwise leave `focus/` out and save the app space.

This folder is bundled as a **folder reference**, so the structure is
preserved and adding a clip needs only a rebuild — no `xcodegen generate`.
Keep clips short, **muted**, and seamlessly looping (first frame ≈ last).
