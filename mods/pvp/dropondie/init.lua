dropondie = {}

local function drop_list(pos, player, listname)
	local initial_stuff = ctf_modebase.player.get_initial_stuff(player)
	local inv = player:get_inventory()
	local invlist = inv:get_list(listname)
	local newlist = {}

	-- Move initial stuff from old list to new list
	for list_i, item in ipairs(invlist) do
		for stuff_i = 1, #initial_stuff do
			-- Initialize this within loop so that the value can be changed within the loop
			local i_item = initial_stuff[stuff_i]
			if item:get_name() == i_item:get_name() then
				-- Try to take out i_count
				local count, i_count = item:get_count(), i_item:get_count()
				local taken_item = item:take_item(i_count)
				local taken_count = taken_item:get_count()

				-- Add taken item to new list
				newlist[list_i] = taken_item
				if taken_count < i_count then
					-- If full count wasn't recovered, update initial item's count
					initial_stuff[stuff_i]:set_count(i_count - taken_count)
				else
					-- Else remove item so as to not count it again
					initial_stuff[stuff_i]:clear()
					initial_stuff[stuff_i] = nil
				end
				invlist[list_i] = item
			end
		end
	end

	-- Drop all remaining items in old list
	for _, item in ipairs(invlist) do
		local obj = minetest.add_item(pos, item)
		if obj then
			obj:set_velocity({ x = math.random(-1, 1), y = 5, z = math.random(-1, 1) })
		end
	end

	-- Set new list containing only initial stuff
	inv:set_list(listname, newlist)
end

function dropondie.drop_all(player)
	ctf_modebase.player.remove_bound_items(player)
	ctf_modebase.player.remove_initial_stuff(player)

	local pos = player:get_pos()
	pos.y = math.floor(pos.y + 0.5)

	drop_list(pos, player, "main")
end

if ctf_core.settings.server_mode ~= "mapedit" then
	minetest.register_on_dieplayer(dropondie.drop_all)
	minetest.register_on_leaveplayer(dropondie.drop_all)
end
