minetest.register_node("slower:cobweb", {
    description = "Sticky Cobweb",
    drawtype = "plantlike",
    tiles = {"cobweb.png"},
    sunlight_propagates = true,
    paramtype = "light",
	inventory_image = "cobweb.png",
    groups = {snappy = 1},
    walkable = false,
    buildable_to = false,
})

minetest.register_node("slower:quicksand", {
	description = "Quicksand",
    tiles = {"quicksand.png"},
    inventory_image = "cobweb.png",
	groups = {crumbly = 2},
})

local time = 0
local quicksand_modifier = {
    speed   = 0.5,
	jump    = 0.9,
	gravity = 1
}
local cobweb_modifier = {
    speed   = 0.1,
	jump    = 0,
	gravity = 0.1
}

minetest.register_globalstep(function(dtime)

	time = time + dtime

	-- Run the rest of the code every 0.1 seconds
	if time < 0.1 then
		return
	end

	time = 0
    for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()

		local pos = player:get_pos()

        local node_below = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})
        local node_feet = minetest.get_node({x = pos.x, y = pos.y, z = pos.z})
        local node_head = minetest.get_node({x = pos.x, y = pos.y + 1, z = pos.z})
        if node_below.name == "slower:quicksand" then
            physics.set(name, "quicksand", quicksand_modifier)
        else
            physics.remove(name, "quicksand")
        end

        if node_feet.name == "slower:cobweb" or node_head.name == "slower:cobweb" then
            physics.set(name, "cobweb", cobweb_modifier)
        else
            physics.remove(name, "cobweb")
        end
	end
end)
