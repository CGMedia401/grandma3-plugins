# GrandMA3 Plugins

Custom GrandMA3 onPC/console plugins for CG Media & Lites. Each folder
holds only the most recent version of that plugin.

## PluginTemplate
Starting point for any new plugin. Has the self-installing CG logo
pipeline and the CG-branded window chrome (titlebar + logo + close
button + a proven Stretch-content/Fixed-button DialogFrame layout)
already wired up, with clear TODO markers for the actual content.
Copy this folder, rename it, find/replace "PluginTemplate" throughout,
and build from there instead of starting from scratch. See the header
comment inside PluginTemplate.lua for the full instructions.

## GroupCleanupV4
Clears unused color-group layout items (Layout 2 "Color" and Layout 5
"Position Phaser") for groups you're not running that night. Custom UI
window with a CG-branded pink titlebar/logo and color-coded checkboxes
per group, both self-installing on first run via embedded base64
textures - copy the .lua anywhere and it deploys its own images, no
manual file copying per machine.

## SaveShowAs4
Prompts to rename the show before saving (pre-filled with the current
show name), then appends an HHMM timestamp and saves - to the current
drive (console/onPC) and, on top of that, to every USB stick plugged
in at save time. Same CG-branded pink window chrome and self-installing
logo pipeline as GroupCleanupV4.

## PixelGroupStoreV2
Selects a Strike M, JDC, or Pixel Line IP fixture's RGB and White
pixels, arranges each into a clean Selection Grid block, and stores
each into a named group - supports a single fixture or a `Thru` range
across multiple trusses, with per-fixture-type pixel addressing
profiles, an RGB/White orientation confirm step (with independent
invert X/Y), and pink CG-branded window chrome throughout, including a
custom swatch-colored group-picker popup.

## DeleteHardValues
Scans every sequence/cue/cue-part for attribute values that are plain
hard values (not linked to a preset or recipe) and writes a plain-text
report. Scan/report only - does not delete anything yet.

---

All plugins use the two-file `.xml` (descriptor) + `.lua` (source) format -
import the `.xml` via Plugin Pool -> Import in GrandMA3.
