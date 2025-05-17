local location = {
	"Arm_Right",          -- default bone
	{x=0, y=5.5, z=3},    -- default position
	{x=-90, y=225, z=90}, -- default rotation
	{x=0.3, y=0.3, z=0.25},     -- default scale
}

local players = {}

local S = minetest.get_translator(minetest.get_current_modname())

minetest.register_item("wield3d:hand", {
	type = "none",
	wield_image = "blank.png",
})

minetest.register_entity("wield3d:entity", {
	visual = "wielditem",
	wield_item = "wield3d:hand",
	visual_size = location[4],
	physical = false,
	makes_footstep_sound = false,
	backface_culling = false,
	static_save = false,
	pointable = false,
	glow = 7,
	on_punch = function() return true end,
})

local function update_entity(player)
	local pname = player:get_player_name()
	local item = player:get_wielded_item():get_name()

	if item == "" then
		item = "wield3d:hand"
	end

	if players[pname].item == item then
		return
	end
	players[pname].item = item

	players[pname].entity:set_properties({wield_item = item})
end

local globalstep_timer = 0
minetest.register_globalstep(function(dtime)
	globalstep_timer = globalstep_timer + dtime
	if globalstep_timer < 0.5 then return end

	globalstep_timer = 0

	for _, player in ipairs(minetest.get_connected_players()) do
		if players[player:get_player_name()] ~= nil then
			update_entity(player)
		end
	end
end)

local function add_wielditem(player)
	local entity = minetest.add_entity(player:get_pos(), "wield3d:entity")
	local setting = ctf_settings.get(player, "use_old_wielditem_display")

	entity:set_attach(
		player,
		location[1], location[2], location[3],
		setting == "false"
	)
	players[player:get_player_name()] = {entity=entity, item="wield3d:hand"}

	player:hud_set_flags({wielditem = (setting == "true")})
	update_entity(player)
end

local function remove_wielditem(player)
	local pname = player:get_player_name()
	if players[pname] ~= nil then
		players[pname].entity:remove()
		players[pname] = nil
	end
end

minetest.register_on_joinplayer(add_wielditem)
minetest.register_on_leaveplayer(remove_wielditem)


ctf_settings.register("use_old_wielditem_display", {
	label = S("Use old wielditem display"),
	type = "bool",
	default = "true",
	description = S("Will use Luanti's default method of showing the wielded item.") .. "\n" ..
		S("This won't show custom animations, but might be less jarring"),
	on_change = function(player, new_value)
		remove_wielditem(player)
		add_wielditem(player)
	end,
})
