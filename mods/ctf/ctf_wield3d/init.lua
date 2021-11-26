local location = {
	"Arm_Right",          -- default bone
	{x=0, y=5.5, z=3},    -- default position
	{x=-90, y=225, z=90}, -- default rotation
	{x=0.25, y=0.25},     -- default scale
}

local players = {}

minetest.register_item("ctf_wield3d:hand", {
	type = "none",
	wield_image = "blank.png",
})

minetest.register_entity("ctf_wield3d:entity", {
	visual = "wielditem",
	wield_item = "ctf_wield3d:hand",
	visual_size = location[4],
	physical = false,
	makes_footstep_sound = false,
	backface_culling = false,
	static_save = false,
	pointable = false,
	on_punch = function() return true end,
})

local function update_entity(player)
	local pname = player:get_player_name()
	local item = player:get_wielded_item():get_name()

	if item == "" then
		item = "ctf_wield3d:hand"
	end

	if players[pname].item == item then
		return
	end
	players[pname].item = item

	players[pname].entity:set_properties({wield_item = item})
end

local function update_all()
	for _, player in ipairs(minetest.get_connected_players()) do
		if players[player:get_player_name()] ~= nil then
			update_entity(player)
		end
	end

	minetest.after(1, update_all)
end

minetest.after(1, update_all)

minetest.register_on_joinplayer(function(player)
	local entity = minetest.add_entity(player:get_pos(), "ctf_wield3d:entity")
	entity:set_attach(player, location[1], location[2], location[3])
	players[player:get_player_name()] = {entity=entity, item="ctf_wield3d:hand"}

	update_entity(player)
end)

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	if players[pname] ~= nil then
		players[pname].entity:remove()
		players[pname] = nil
	end
end)
