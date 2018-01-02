Sprint Mod For Minetest by GunshipPenguin  

Allows the player to sprint by either double tapping w or pressing e. 
By default, sprinting will make the player travel 80% faster and 
allow him/her to jump 10% higher. Also adds a stamina bar that goes 
down when the player sprints and goes up when he/she isn't 
sprinting.

This mod is compatible with the HUD bars [hudbars] mod, but does
not depend on it. In this care, a green HUD bar will be displayed,
also showing a number.
If this mod is not present, a standard statbar with 0-20
“half-arrows” is shown, which is a bit more coarse than the HUD
bar version.


Licence: CC0 (see COPYING file)

---

This mod can be configured by changing the variables declared in 
the start of init.lua. The following is a brief explanation of each 
one.

SPRINT_METHOD (default 1)

What a player has to do to start sprinting. 0 = double tap w, 1 = press e.
Note that if you have the fast privlige, and have the fast 
speed turned on, you will run very, very fast. You can toggle this 
by pressing j.
 
SPRINT_SPEED (default 1.5)
 
How fast the player will move when sprinting as opposed to normal 
movement speed. 1.0 represents normal speed so 1.5 would mean that a 
sprinting player would travel 50% faster than a walking player and 
2.4 would mean that a sprinting player would travel 140% faster than 
a walking player.

SPRINT_JUMP (default 1.1)

How high the player will jump when sprinting as opposed to normal 
jump height. Same as SPRINT_SPEED, just controls jump height while 
sprinting rather than speed.

SPRINT_STAMINA (default 20)

How long the player can sprint for in seconds. Each player has a 
stamina variable assigned to them, it is initially set to 
SPRINT_STAMINA and can go no higher. When the player is sprinting, 
this variable ticks down once each second, and when it reaches 0, 
the player stops sprinting. It ticks back up when the player isn't 
sprinting and stops at SPRINT_STAMINA. Set this to a huge value if 
you want unlimited sprinting.

SPRINT_TIMEOUT (default 0.5)

Only used if SPRINT_METHOD = 0.
How much time the player has after releasing w, to press w again and 
start sprinting. Setting this too high will result in unwanted 
sprinting and setting it too low will result in it being 
difficult/impossible to sprint.
