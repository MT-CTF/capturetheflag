dropondie = {}

local registered_drop_filters = {}

-- return true to drop, false to destroy
function dropondie.register_drop_filter(func, priority)
	table.insert(registered_drop_filters,
	priority or (#registered_drop_filters + 1),
	func)
end

local blacklist_drop = {}
dropondie.register_drop_filter(function(player, itemname)
	return table.indexof(blacklist_drop, itemname) == -1
end)

local function drop(player, pos, itemstack)
	local it = itemstack:take_item(itemstack:get_count())
	local sname = it:get_name()

	for i=1, #registered_drop_filters do
		if not registered_drop_filters[i](player, sname) then
			return itemstack
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

local function drop_list(player, pos, inv, list)
	for i = 1, inv:get_size(list) do
		drop(player, pos, inv:get_stack(list, i))
		inv:set_stack(list, i, nil)
	end
end

function dropondie.drop_all(player)
	local pos = player:get_pos()
	pos.y = math.floor(pos.y + 0.5)

	local inv = player:get_inventory()
	for _, item in pairs(give_initial_stuff.get_stuff(player)) do
		inv:remove_item("main", ItemStack(item))
	end
	drop_list(player, pos, inv, "main")
	drop_list(player, pos, inv, "craft")
end

if ctf_core.settings.server_mode ~= "mapedit" then
	minetest.register_on_dieplayer(dropondie.drop_all)
	minetest.register_on_leaveplayer(dropondie.drop_all)
end
