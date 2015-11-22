=== THROWING ENHANCED for MINETEST ===

Inroduction:
This mod adds many bows and arrows to Minetest.
It began as a fork of PilzAdam's throwing mod with some enhancements from me. Enjoy!
Echoes91

How to install:
http://wiki.minetest.com/wiki/Installing_Mods

How to use the mod:
Select a bow and place the arrows into the slot next to it; shoot with left mouse click. 
Every shoot will take 1 arrow from your inventory and wears out the bow.
Select a spear and attack with left mouse click; it will be used as a melee weapon if pointing any target, otherwise it will be thrown.

License:
This mod was originally published by Jeija and reworked by PilzAdam
Sourcecode: LGPLv2.1 (see http://www.gnu.org/licenses/lgpl-2.1.html)
Grahpics & sounds: CC-BY 3.0 (see http://creativecommons.org/licenses/by/3.0/legalcode)


Changelog:

Update 1.4.1:
- Fixed spears not retaining wear
- Improved textures
- Torch arrows have light trail

Update 1.4:
- Added spears, capable of melee and ranged attacks
- Improved arrows textures

Update 1.3:
- Added automated arbalest, the ultimate weapon 
- New arbalest texture coherent with steel color

Update 1.2:
- Added arbalest
- Defaults initialized

Update 1.1:
- Added crossbow
- Code shrink
- Offensive arrows go through flora's and farming's
- Small fixes

Update 1.0:
- Definitive reload, unload and shot system based on tool metadata, new global functions, no more "throw" privilege
- New textures for loaded bows
- Fireworks arrows to celebrate!

Update 1.0rc2:
- Fixed "compare nil with number" due to self.break not being retained
- Filled conf.example's list
- Added Royal bow

Update 1.0rc1:
- Added longbow and removed golden bow, definitive bow set for stable release. Feature freeze
- Fixed torch arrow recipe, thanks to Excalibur Zero
- Removed config.lua, configuration now goes int throwing.config, see example

Update 0.9.8:
- New damage calculation for offensive arrows based on arrow's speed and material. Beware that dependency is more than linear for both, so that differences between arrows will be enhanced if they're shot at higher speed.
- Fixed bug that blocked ability to shot after shooting with empty arrow stack.
- Removed annoying debug symbols

Update 0.9.7:
- Added visual feedback for reload
- Fixed reload for players who die while reloading and for multiplayer
- Changed license for the code to LGPLv2

Update 0.9.6:
- Any bow and arrow is now deactivable under config.lua, which won't be overwritten
- Changed license for media to CC-BY

Update 0.9.5:
- Added shell arrows
- Revised sounds and some textures
- General balancing of bow's statistics

Update 0.9.4:
- New bow texture
- Made recipes coherent

Update 0.9.3:
- Added symmetric recipes, fixed golden bow recipe
- Adjusted few parameters

Update 0.9.2:
- Added a chance to break for many arrows, so they don't last forever and outclass any other tool 
- Build and torch arrows won't build on fluids and torches any more, build arrows won't place torches
- TNT arrow digs instead if removing blocks, eventual indestructible nodes are safe
- Added golden bow with possible new bow style
- Changed the (bit OP) composite bow resistance and new recipe
- New teleport arrow recipe, cheaper but single use

Update 0.9.1:
- Good improvement for torch arrows, now they always attach and are often turned to the right direction
- Git repository will make things nicer

Update 0.9:
- Now bows have reload times! They depend on weight and quality, anyway no more machine-gun-style shell swarms
- Fixed build arrow behavior, now it placed and consumes the node from the slot [b]right next to the arrow[/b] or drops the item beside it if not a node; no more disappearing nor 'CONTENT_IGNORE' errors
- Code cleanup and rationalization

Update 0.8.1: 
- Fixed wrong texture reference which made some arrows get a bad color during flight.
- Now bows have different stiffness besides wear resistances, which means that they shot arrows at different initial speed and learning to hit the target will become even harder.
 Get rid of the old .env: API
 Added new bows and new offensive, utility and harmful arrows (these are just my categories, they're not present into the code at all).
 Removed stone bow, at least as long as somebody discovers an elastic rock ;)
 Non-exploding arrows won't disappear any more after hitting target.