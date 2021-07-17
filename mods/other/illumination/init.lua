illumination = {}
illumination.playerLights = {}

local lightPoint = {
	drawtype = "airlike",
	paramtype = "light",
	groups = {not_in_creative_inventory=1},
	sunlight_propagates = true,
	can_dig = false,
	walkable = false,
	buildable_to = true,
	light_source = 4,
	selection_box = {
        type = "fixed",
        fixed = {0, 0, 0, 0, 0, 0}},
}

minetest.register_node("illumination:light_faint", lightPoint)
lightPoint.light_source = 8
minetest.register_node("illumination:light_dim", lightPoint)
lightPoint.light_source = 12
minetest.register_node("illumination:light_mid", lightPoint)
lightPoint.light_source = 15
minetest.register_node("illumination:light_full", lightPoint)

minetest.register_abm({ --This should clean up nodes that don't get deleted for some reason
	nodenames={"illumination:light_faint","illumination:light_dim","illumination:light_mid","illumination:light_full"},
	interval=1,
	chance=1,
	action = function(pos)
		local canExist = false
		for _, player in ipairs(minetest.get_connected_players()) do
			if illumination.playerLights[player:get_player_name()] then
				local pos1 = illumination.playerLights[player:get_player_name()].pos
				if pos1 then
					if vector.equals(pos1,pos) then
						canExist = true
					end
				end
			end
		end
		if not canExist then
			minetest.remove_node(pos)
		end
	end
})
minetest.register_on_joinplayer(function(player)
	illumination.playerLights[player:get_player_name()] = {
		bright = 0,
		pos = vector.new(player:get_pos())
	}

end)

minetest.register_on_leaveplayer(function(player, _)
	local player_name = player:get_player_name()
	local remainingPlayers = {}
	for _, online in pairs(minetest.get_connected_players()) do
		if online:get_player_name() ~= player_name then
			remainingPlayers[online:get_player_name()] = illumination.playerLights[online:get_player_name()]
			
		end
	end
	illumination.playerLights = remainingPlayers
end)

local function canLight(nodeName) 
	return (nodeName == "air" or nodeName == "illumination:light_faint" or nodeName == "illumination:light_dim" or nodeName == "illumination:light_mid" or nodeName == "illumination:light_full")
end

minetest.register_globalstep(function(dtime)
	for _, player in ipairs(minetest.get_connected_players()) do
		if illumination.playerLights[player:get_player_name()] then
			local light = 0
			if minetest.registered_nodes[player:get_wielded_item():get_name()] then 
				light = minetest.registered_nodes[player:get_wielded_item():get_name()].light_source
			end
			
			local pos = player:get_pos()
			pos.x = math.floor(pos.x + 0.5)
			pos.y = math.floor(pos.y + 0.5)
			pos.z = math.floor(pos.z + 0.5)
			if not canLight(minetest.get_node(pos).name) then
				if canLight(minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z}).name) then
					pos = {x=pos.x, y=pos.y+1, z=pos.z}
				elseif canLight(minetest.get_node({x=pos.x, y=pos.y+2, z=pos.z}).name) then
					pos = {x=pos.x, y=pos.y+2, z=pos.z}
				elseif canLight(minetest.get_node({x=pos.x, y=pos.y-1, z=pos.z}).name) then
					pos = {x=pos.x, y=pos.y-1, z=pos.z}
				elseif canLight(minetest.get_node({x=pos.x+1, y=pos.y, z=pos.z}).name) then
					pos = {x=pos.x+1, y=pos.y, z=pos.z}
				elseif canLight(minetest.get_node({x=pos.x, y=pos.y, z=pos.z+1}).name) then
					pos = {x=pos.x, y=pos.y, z=pos.z+1}
				elseif canLight(minetest.get_node({x=pos.x-1, y=pos.y, z=pos.z}).name) then
					pos = {x=pos.x-1, y=pos.y, z=pos.z}
				elseif canLight(minetest.get_node({x=pos.x, y=pos.y, z=pos.z-1}).name) then
					pos = {x=pos.x, y=pos.y, z=pos.z-1}
				elseif canLight(minetest.get_node({x=pos.x+1, y=pos.y+1, z=pos.z}).name) then
					pos = {x=pos.x+1, y=pos.y+1, z=pos.z}
				elseif canLight(minetest.get_node({x=pos.x-1, y=pos.y+1, z=pos.z}).name) then
					pos = {x=pos.x-1, y=pos.y+1, z=pos.z}
				elseif canLight(minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z+1}).name) then
					pos = {x=pos.x, y=pos.y+1, z=pos.z+1}
				elseif canLight(minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z-1}).name) then
					pos = {x=pos.x, y=pos.y+1, z=pos.z-1}
				end
			end
			local pos1 = illumination.playerLights[player:get_player_name()].pos
			local lightLast = illumination.playerLights[player:get_player_name()].bright
			
			illumination.playerLights[player:get_player_name()] = {}
			if canLight(minetest.get_node(pos).name) then
				illumination.playerLights[player:get_player_name()].bright = light
				illumination.playerLights[player:get_player_name()].pos = pos
				local nodeName = "air"
				if light > 2 then
					nodeName = "illumination:light_faint"
				end
				if light > 7 then
					nodeName = "illumination:light_dim"
				end
				if light > 10 then
					nodeName = "illumination:light_mid"
				end
				if light > 13 then
					nodeName = "illumination:light_full"
				end
				if nodeName then
					minetest.set_node(pos, {name=nodeName})
				end
			end
			
			if pos1 then
				if canLight(minetest.get_node(pos1).name) then
					if not vector.equals(pos, pos1) then
						minetest.remove_node(pos1)
					end
				end
			end
		end
	end
end)