# GrandMA3 Plugins

Custom GrandMA3 onPC/console plugins for CG Media & Lites.

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
window with a CG-branded titlebar logo and color-coded checkboxes per
group, both self-installing on first run via embedded base64 textures -
copy the .lua anywhere and it deploys its own images, no manual file
copying per machine.

## SaveShowAs3
Prompts to rename the show before saving, then appends a timestamp and
saves. Custom UI window matching GroupCleanupV4's look (CG logo in the
titlebar, same self-installing texture pipeline), with YES/NO buttons
replacing the stock PopupInput dialog.

All plugins use the two-file `.xml` (descriptor) + `.lua` (source) format -
import the `.xml` via Plugin Pool -> Import in GrandMA3.
