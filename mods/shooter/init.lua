local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath.."/shooter.lua")

if SHOOTER_ENABLE_CROSSBOW == true then
	dofile(modpath.."/crossbow.lua")
end
if SHOOTER_ENABLE_GUNS == true then
	dofile(modpath.."/guns.lua")
end
if SHOOTER_ENABLE_FLARES == true then
	dofile(modpath.."/flaregun.lua")
end
if SHOOTER_ENABLE_HOOK == true then
	dofile(modpath.."/grapple.lua")
end
if SHOOTER_ENABLE_GRENADES == true then
	dofile(modpath.."/grenade.lua")
end
if SHOOTER_ENABLE_ROCKETS == true then
	dofile(modpath.."/rocket.lua")
end
if SHOOTER_ENABLE_TURRETS == true then
	dofile(modpath.."/turret.lua")
end

