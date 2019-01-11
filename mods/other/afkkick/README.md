Afk Kick mod for Minetest by GunshipPenguin

Kicks players after they are Afk for an amount of time. By default, 
players are kicked after five minutes, although this can be configured.

Licence: CC0 (see COPYING file)

This mod can be configured by changing the variables declared in the 
start of init.lua. The following is a brief explanation of each one.

MAX_INACTIVE_TIME (default 300)

Maximum amount of time that a player may remain AFK (in seconds) 
before being kicked.

CHECK_INTERVAL (default 1)

Time between checks for inactivity (In seconds)

WARN_TIME (default 20)

Number of seconds remaining before being kicked that a player will 
start to be warned via chat message.
