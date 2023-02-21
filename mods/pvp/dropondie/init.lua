dropondie = {}

local function drop_list(pos, inv, list)
	for _, item in ipairs(inv:get_list(list)) do
		local obj = minetest.add_item(pos, item)

		if obj then
			obj:set_velocity({ x = math.random(-1, 1), y = 5, z = math.random(-1, 1) })
		end
	end

	inv:set_list(list, {})
end

function dropondie.drop_all(player)
	if not ctf_teams.get(player) then return end

	ctf_modebase.player.remove_bound_items(player)
	ctf_modebase.player.remove_initial_stuff(player)

	local pos = player:get_pos()
	pos.y = math.floor(pos.y + 0.5)

	drop_list(pos, player:get_inventory(), "main")
end

if ctf_core.settings.server_mode ~= "mapedit" then
	minetest.register_on_dieplayer(dropondie.drop_all)
	minetest.register_on_leaveplayer(dropondie.drop_all)
end
