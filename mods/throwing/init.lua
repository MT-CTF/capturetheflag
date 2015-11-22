throwing_arrows = {
	{"throwing:arrow_steel", "throwing:arrow_steel_entity"},
	{"throwing:arrow_stone", "throwing:arrow_stone_entity"},
	{"throwing:arrow_obsidian", "throwing:arrow_obsidian_entity"},
	{"throwing:arrow_fire", "throwing:arrow_fire_entity"},
	{"throwing:arrow_teleport", "throwing:arrow_teleport_entity"},
	{"throwing:arrow_dig", "throwing:arrow_dig_entity"},
	{"throwing:arrow_build", "throwing:arrow_build_entity"},
	{"throwing:arrow_tnt", "throwing:arrow_tnt_entity"},
	{"throwing:arrow_torch", "throwing:arrow_torch_entity"},
	{"throwing:arrow_diamond", "throwing:arrow_diamond_entity"},
	{"throwing:arrow_shell", "throwing:arrow_shell_entity"},
	{"throwing:arrow_fireworks_blue", "throwing:arrow_fireworks_blue_entity"},
	{"throwing:arrow_fireworks_red", "throwing:arrow_fireworks_red_entity"},
}

dofile(minetest.get_modpath("throwing").."/defaults.lua")

local input = io.open(minetest.get_modpath("throwing").."/throwing.conf", "r")
if input then
	dofile(minetest.get_modpath("throwing").."/throwing.conf")
	input:close()
	input = nil
end

dofile(minetest.get_modpath("throwing").."/functions.lua")

dofile(minetest.get_modpath("throwing").."/tools.lua")

dofile(minetest.get_modpath("throwing").."/standard_arrows.lua")

if minetest.get_modpath('fire') and minetest.get_modpath('bucket') and not DISABLE_FIRE_ARROW then
	dofile(minetest.get_modpath("throwing").."/fire_arrow.lua")
end

if not DISABLE_TELEPORT_ARROW then
	dofile(minetest.get_modpath("throwing").."/teleport_arrow.lua")
end

if not DISABLE_DIG_ARROW then
	dofile(minetest.get_modpath("throwing").."/dig_arrow.lua")
end

if not DISABLE_BUILD_ARROW then
	dofile(minetest.get_modpath("throwing").."/build_arrow.lua")
end

if minetest.get_modpath('fire') and minetest.get_modpath('tnt') and not DISABLE_TNT_ARROW then
	dofile(minetest.get_modpath("throwing").."/tnt_arrow.lua")
end

if not DISABLE_TORCH_ARROW then
	dofile(minetest.get_modpath("throwing").."/torch_arrow.lua")
end

if minetest.get_modpath('tnt') and not DISABLE_SHELL_ARROW then
	dofile(minetest.get_modpath("throwing").."/shell_arrow.lua")
end

if minetest.get_modpath('tnt') then
	dofile(minetest.get_modpath("throwing").."/fireworks_arrows.lua")
end

if minetest.setting_get("log_mods") then
	minetest.log("action", "throwing loaded")
end
