local blacklist_drop = {}

local function drop(pos, itemstack)
	local it = itemstack:take_item(itemstack:get_count())
	local sname = it:get_name()

	for _, item in pairs(blacklist_drop) do
		if sname == item then
			minetest.log("info", "[dropondie] Not dropping " .. sname)
			return
		end
	end

	local obj = minetest.add_item(pos, it)

	if obj then
		obj:set_velocity({ x = math.random(-1, 1), y = 5, z = math.random(-1, 1) })

		local remi = minetest.settings:get("remove_items")
		if minetest.is_yes(remi) then
			obj:remove()
		end
	end
	return itemstack
end

local function drop_list(pos, inv, list)
	for i = 1, inv:get_size(list) do
		drop(pos, inv:get_stack(list, i))
		inv:set_stack(list, i, nil)
	end
end

local function drop_all(player)
	local pos = player:get_pos()
	pos.y = math.floor(pos.y + 0.5)

	local inv = player:get_inventory()
	for _, item in pairs(give_initial_stuff.get_stuff()) do
		inv:remove_item("main", ItemStack(item))
	end
	drop_list(pos, inv, "main")
	drop_list(pos, inv, "craft")
end

minetest.register_on_dieplayer(drop_all)
minetest.register_on_leaveplayer(drop_all)
