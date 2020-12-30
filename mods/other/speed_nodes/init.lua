minetest.register_node("speed_nodes:cobweb", {
	description = "Sticky Cobweb",
	drawtype = "plantlike",
	tiles = {"speed_nodes_cobweb.png"},
	sunlight_propagates = true,
	paramtype = "light",
	inventory_image = "speed_nodes_cobweb.png",
	groups = {snappy = 1},
	walkable = false,
	buildable_to = false,
})

minetest.register_node("speed_nodes:quicksand", { -- irony
	description = "Quicksand",
	tiles = {"speed_nodes_quicksand.png"},
	groups = {crumbly = 2},
})

minetest.register_node("speed_nodes:asphalt", {
	description = "Asphalt",
	tiles = {"speed_nodes_asphalt.png"},
	groups = {cracky = 2},
})

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

local asphalt_modifier = {
	speed   = 1.3,
	jump    = 1,
	gravity = 1
}

local time = 0

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

        if node_below.name == "speed_nodes:quicksand" then
            if not players[name].quicksand then
                physics.set(name, "quicksand", quicksand_modifier)
            end
        else
            if players[name].quicksand then
                physics.remove(name, "quicksand")
            end
        end

        if node_below.name == "speed_nodes:asphalt" then
            if not players[name].asphalt then
                physics.set(name, "asphalt", asphalt_modifier)
            end
        else
            if players[name].asphalt then
                physics.remove(name, "asphalt")
            end
        end
        
		if node_feet.name == "speed_nodes:cobweb" or node_head.name == "speed_nodes:cobweb" then 
			if not players[name].cobweb then
				physics.set(name, "cobweb", cobweb_modifier)
			end
		else
			if players[name].cobweb then
				physics.remove(name, "cobweb")
			end
		end
	end
end)
