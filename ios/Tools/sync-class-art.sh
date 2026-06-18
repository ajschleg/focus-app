#!/bin/zsh
# Sync ClassArt imageset PNGs to the asset-catalog naming convention.
#
#   ios/Tools/sync-class-art.sh [--check] [Class ...]
#
# The app loads class art by imageset *name*: FocusClass.artworkName feeds
# UIImage(named: "ClassArt/<Class>"), which resolves the actual file through
# that imageset's Contents.json. So a PNG dropped into <Class>.imageset only
# shows up once it's named <Class>.png AND Contents.json points at it.
#
# This sweeps every Assets.xcassets/ClassArt/<Class>.imageset and, for each:
#   * renames the dropped-in PNG (any filename) to <Class>.png
#   * points Contents.json at <Class>.png
#   * if several PNGs are present, the newest wins and the rest are removed
#   * a slot with no PNG is left empty (the tint-wash fallback)
# It is idempotent: re-running an already-synced catalog changes nothing.
#
# Just drop your art into the right <Class>.imageset folder and run this; no
# manual renaming. Rebuild afterwards to see it.
#
# Options:
#   --check, -n   report only, change nothing; exit 1 if anything is out of
#                 sync (use as a pre-build / CI guard)
#   --quiet, -q   suppress the per-class in-sync/empty lines; only report
#                 changes/problems and the summary (used by the build phase)
# Args:
#   Class ...     limit the sweep to these classes; default is every imageset.

emulate -L zsh
setopt extended_glob null_glob no_case_glob

check=0
quiet=0
classes=()
for arg in "$@"; do
  case "$arg" in
    --check|-n) check=1 ;;
    --quiet|-q) quiet=1 ;;
    -h|--help)  print -- "usage: ${0:t} [--check] [--quiet] [Class ...]"; exit 0 ;;
    -*)         print -u2 "unknown option: $arg"; exit 2 ;;
    *)          classes+=("$arg") ;;
  esac
done

# "Nothing to report" lines (in sync / empty) — silenced by --quiet.
note() { (( quiet )) || print -- "$@"; }

here="${0:A:h}"
root="$here/../Assets.xcassets/ClassArt"
[[ -d "$root" ]] || { print -u2 "ClassArt catalog not found: $root"; exit 2 }

# Canonical Contents.json bodies (match Tools/add-class-art.sh).
contents_for() {   # $1 = png filename
  print -r -- "{
  \"images\" : [
    {
      \"filename\" : \"$1\",
      \"idiom\" : \"universal\"
    }
  ],
  \"info\" : {
    \"author\" : \"xcode\",
    \"version\" : 1
  }
}"
}
contents_empty() {
  print -r -- "{
  \"images\" : [],
  \"info\" : {
    \"author\" : \"xcode\",
    \"version\" : 1
  }
}"
}

# Which imagesets to process.
if (( ${#classes} )); then
  imagesets=()
  for c in "${classes[@]}"; do
    d="$root/${c}.imageset"
    if [[ -d "$d" ]]; then imagesets+=("$d")
    else print -u2 "  ?  $c — no imageset slot (skipped)"; fi
  done
else
  imagesets=( "$root"/*.imageset(/N) )
fi

insync=0 fixed=0 empty=0 flagged=0

for dir in "${imagesets[@]}"; do
  name=${dir:t:r}
  target="${name}.png"
  contents="$dir/Contents.json"
  pngs=( "$dir"/*.png(.omN) )   # plain files, newest first; any case (no_case_glob)

  # Empty slot: ensure Contents.json declares no image.
  if (( ${#pngs} == 0 )); then
    want="$(contents_empty)"
    if [[ -f "$contents" && "$(<"$contents")" == "$want" ]]; then
      (( empty += 1 )); note "  ·  $name — empty slot (fallback art)"
    elif (( check )); then
      (( flagged += 1 )); print -- "  !  $name — Contents.json names a missing image (would reset)"
    else
      contents_empty > "$contents"; (( fixed += 1 )); print -- "  ✓  $name — cleared dangling Contents.json"
    fi
    continue
  fi

  winner=${pngs[1]}
  extras=( "${(@)pngs[2,-1]}" )        # every PNG but the newest
  needs_rename=0; [[ "${winner:t}" == "$target" ]] || needs_rename=1
  want="$(contents_for "$target")"
  json_ok=0; [[ -f "$contents" && "$(<"$contents")" == "$want" ]] && json_ok=1

  if (( ${#extras} == 0 && needs_rename == 0 && json_ok == 1 )); then
    (( insync += 1 )); note "  ·  $name — in sync"
    continue
  fi

  if (( check )); then
    (( flagged += 1 ))
    (( needs_rename )) && print -- "  !  $name — would rename ${winner:t} → $target"
    for e in "${extras[@]}"; do print -- "  !  $name — would remove stray ${e:t}"; done
    (( json_ok )) || print -- "  !  $name — would update Contents.json"
    continue
  fi

  acts=()
  for e in "${extras[@]}"; do rm -f -- "$e" && acts+=("removed ${e:t}"); done
  (( needs_rename )) && { mv -f -- "$winner" "$dir/$target" && acts+=("renamed ${winner:t} → $target"); }
  (( json_ok )) || { contents_for "$target" > "$contents" && acts+=("wired Contents.json"); }
  (( fixed += 1 )); print -- "  ✓  $name — ${(j:, :)acts}"
done

print --
print -- "summary: ${insync} in sync · ${fixed} fixed · ${empty} empty · ${flagged} flagged"
(( check && flagged )) && { print -- "run without --check to apply."; exit 1; }
exit 0
