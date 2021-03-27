-- Licensed under the MIT license, written by appgurueu.
local players = {}
local blocks_per_second = 5
local resend_notification_seconds = 10
-- Bootstrap 4 "warning" color
local warning_color = 0xFFC107

minetest.register_on_joinplayer(function(player)
	-- player has to wait after join before they can place a node
	players[player:get_player_name()] = {
		last_notification_sent = -math.huge
	}
end)

minetest.register_on_leaveplayer(function(player)
	players[player:get_player_name()] = nil
end)

minetest.register_on_placenode(function(pos, _newnode, placer, oldnode, _itemstack, pointed_thing)
	local name = placer:get_player_name()
	if not ItemStack(minetest.get_node(pointed_thing.under).name):get_definition().pointable then
		-- This should happen rarely
		hud_event.new(name, {
			name  = "place_limit:unpointable",
			color = warning_color,
			value = "Block not pointable (dug/replaced)!",
		})
		minetest.set_node(pos, oldnode)
		return true
	end
	local time = minetest.get_us_time()
	local placements = players[name]
	for i = #placements, 1, -1 do
		if time - placements[i] > 1e6 then
			placements[i] = nil
		end
	end
	if #placements >= blocks_per_second then
		if (time - placements.last_notification_sent) / 1e6 >= resend_notification_seconds then
			hud_event.new(name, {
				name  = "place_limit:speed",
				color = warning_color,
				value = "Placing too fast!",
			})
			placements.last_notification_sent = time
		end
		minetest.set_node(pos, oldnode)
		return true
	end
	table.insert(placements, 1, time)
end)
