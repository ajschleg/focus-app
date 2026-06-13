#!/bin/zsh
# Drop a class figure into the app.
#
#   ./add-class-art.sh <ClassName> <path/to/image.png>
#
# Copies the image into Assets.xcassets/ClassArt/<ClassName>.imageset as
# <ClassName>.png and points its Contents.json at it, so the app's name
# lookup (FocusClass.artworkName) picks it up on the next build. The 30
# imageset slots already exist (empty = the tint-wash fallback shows); this
# just fills one. Rebuild afterwards to see it.
#
# Class names: Wanderer, Ascetic, Warrior, Scholar, Mystic, Artisan, Bard,
# Keeper, Druid, Monk, Templar, Wizard, Paladin, Blacksmith, Ranger,
# Philosopher, Artificer, Sage, Alchemist, Naturalist, Calligrapher, Cleric,
# Candlekeeper, Shaman, Jester, Tinker, Herbalist, Innkeeper, Shepherd,
# Homesteader.

set -e
name="$1"
src="$2"
here="${0:A:h}"
imageset="$here/../Assets.xcassets/ClassArt/$name.imageset"

if [[ -z "$name" || -z "$src" ]]; then
  echo "usage: $0 <ClassName> <path/to/image.png>" >&2
  exit 1
fi
if [[ ! -d "$imageset" ]]; then
  echo "no slot for '$name' — check the spelling against the list in this script's header" >&2
  exit 1
fi
if [[ ! -f "$src" ]]; then
  echo "image not found: $src" >&2
  exit 1
fi

cp "$src" "$imageset/$name.png"
cat > "$imageset/Contents.json" <<JSON
{
  "images" : [
    {
      "filename" : "$name.png",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

echo "added $name → $imageset/$name.png"
echo "rebuild to see it (and pick '$name' from the debug class menu)."
