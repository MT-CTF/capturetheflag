local powered_players = {}

local function increase_caps(player)
	local inv = player:get_inventory()

	local lists = inv:get_lists()
	for _, list in pairs(lists) do
		for _, stack in pairs(list) do
			stack:get_meta():set_string("description", nil)
			if not stack:is_empty() then
				stack:get_meta():set_tool_capabilities(nil)
				local caps = stack:get_tool_capabilities()

				local group = caps.groupcaps.cracky
				if group then
					print("===================")
					print("Name: " .. stack:get_name())
					print("From: " .. dump(caps.groupcaps.cracky))

					local lowest = 4
					for i=1, 4 do
						if group.times[i] then
							lowest = i
							break
						end
					end

					print("Lowest: " .. dump(lowest))

					local slowest_normal = group.times[lowest]
					for i=1, lowest - 1 do
						group.times[i] = slowest_normal * (lowest - i + 1)
					end

					print("To: " .. dump(caps.groupcaps.cracky))
					print("===================")

					stack:get_meta():set_string("description", "POWERED")
				end

				stack:get_meta():set_tool_capabilities(caps)
			end
		end
	end
	inv:set_lists(lists)
end

local function reset_caps(player)
	local inv = player:get_inventory()

	local lists = inv:get_lists()
	for _, list in pairs(lists) do
		for _, stack in pairs(list) do
			stack:set_tool_capabilities(nil)
		end
	end
	inv:set_lists(lists)
end

local function force_update(player)
	local z = ctf_map.get_team_relative_z(player)
	if z < 0 then
		reset_caps(player)
		powered_players[pname] = nil
	else
		increase_caps(player)
		powered_players[pname] = true
	end
end

local function check_sides()
	for _, player in pairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local z = ctf_map.get_team_relative_z(player)
		local has_powered = powered_players[pname]
		if z < 0 and has_powered then
			reset_caps(player)
			powered_players[pname] = nil
		elseif z > 5 and not has_powered then
			increase_caps(player)
			powered_players[pname] = true
		end
	end

	minetest.after(2, check_sides)
end
minetest.after(2, check_sides)

minetest.register_on_player_inventory_action(function(player, action, inventory, inventory_info)

end)
