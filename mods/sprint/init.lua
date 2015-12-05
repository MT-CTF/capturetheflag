--[[
Sprint mod for Minetest by GunshipPenguin

To the extent possible under law, the author(s)
have dedicated all copyright and related and neighboring rights 
to this software to the public domain worldwide. This software is
distributed without any warranty. 
]]

--Configuration variables, these are all explained in README.md
SPRINT_METHOD = 1
SPRINT_SPEED = 1.8
SPRINT_JUMP = 1.1
SPRINT_STAMINA = 20
SPRINT_TIMEOUT = 0.5 --Only used if SPRINT_METHOD = 0

if minetest.get_modpath("hudbars") ~= nil then
	hb.register_hudbar("sprint", 0xFFFFFF, "Stamina",
		{ bar = "sprint_stamina_bar.png", icon = "sprint_stamina_icon.png" },
		SPRINT_STAMINA, SPRINT_STAMINA,
		false, "%s: %.1f/%.1f")
	SPRINT_HUDBARS_USED = true
else
	SPRINT_HUDBARS_USED = false
end

if SPRINT_METHOD == 0 then
	dofile(minetest.get_modpath("sprint") .. "/wsprint.lua")
elseif SPRINT_METHOD == 1 then
	dofile(minetest.get_modpath("sprint") .. "/esprint.lua")
else
	minetest.log("error", "Sprint Mod - SPRINT_METHOD is not set properly, using e to sprint")
	dofile(minetest.get_modpath("sprint") .. "/esprint.lua")
end
