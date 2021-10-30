ctf_map.treasurefy_node = function(pos, node, clicker)
	if not ctf_modebase.current_mode then return end

	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	for item, def in pairs(ctf_modebase:get_current_mode().treasures or {}) do
		local treasure = ItemStack(item)

		for c = 1, def.max_stacks or 1, 1 do
			if math.random() < (def.rarity or 0.5) then
				treasure:set_count(math.random(def.min_count or 1, def.max_count or 1))
				inv:add_item("main", treasure)
			end
		end
	end
end
