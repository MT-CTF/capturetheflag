local S = minetest.get_translator("ctf")

local function stack_list_to_map(stacks)
	local map = {}
	for i = 1, #stacks do
		map[ItemStack(stacks[i]):get_name()] = true
	end
	return map
end

-- Returns true if  the item shouldn't be allowed to be dropped etc
local function is_class_blacklisted(player, itemname)
	local class = ctf_classes.get(player)
	local items = stack_list_to_map(class.properties.item_blacklist)
	return items[itemname]
end


give_initial_stuff.register_stuff_provider(function(player)
	local class = ctf_classes.get(player)
	return class.properties.initial_stuff
end, 1)


local function remove_blacklist_in_list(list, blacklist_map)
	local removed = false
	for i=1, #list do
		if blacklist_map[ItemStack(list[i]):get_name()] then
			list[i] = ""
			removed = true
		end
	end
	return removed
end


ctf_classes.register_on_changed(function(player, old, new)
	local inv = player:get_inventory()

	if not old then
		old = ctf_classes.__classes[ctf_classes.default_class]
	end

	local blacklist = old.properties.item_blacklist
	if old and #blacklist > 0 then
		local blacklist_map = stack_list_to_map(blacklist)
		for listname, list in pairs(inv:get_lists()) do
			if remove_blacklist_in_list(list, blacklist_map) then
				inv:set_list(listname, list)
			end
		end
	end

	do
		assert(new)

		local items = new.properties.initial_stuff
		for i = 1, #items do
			inv:add_item("main", ItemStack(items[i]))
		end
	end
end)

local old_item_drop = minetest.item_drop
minetest.item_drop = function(itemstack, player, pos)
	if is_class_blacklisted(player, itemstack:get_name()) then
		minetest.chat_send_player(player:get_player_name(),
			"You're not allowed to drop class items!")
		return itemstack
	else
		return old_item_drop(itemstack, player, pos)
	end
end

local old_is_allowed = ctf_map.is_item_allowed_in_team_chest
ctf_map.is_item_allowed_in_team_chest = function(listname, stack, player)
	if is_class_blacklisted(player, stack:get_name()) then
		minetest.chat_send_player(player:get_player_name(),
			"You're not allowed to put class items in the chest!")
		return false
	else
		return old_is_allowed(listname, stack, player)
	end
end

dropondie.register_drop_filter(function(player, itemname)
	return not is_class_blacklisted(player, itemname)
end)


local function protect_metadata_inventory(nodename)
	local def = assert(minetest.registered_nodes[nodename])

	local function wrap(defname)
		local old = def[defname]
		def[defname] = function(pos, listname, index, stack, player, ...)
			if is_class_blacklisted(player, stack:get_name()) then
				minetest.chat_send_player(player:get_player_name(),
					S("You're not allowed to put class items in @1!", def.description or "?"))
				return 0
			end

			return old(pos, listname, index, stack, player, ...)
		end
	end

	wrap("allow_metadata_inventory_put")
	wrap("allow_metadata_inventory_take")

	minetest.register_node(":" .. nodename, def)
end

protect_metadata_inventory("furnace:furnace")
protect_metadata_inventory("furnace:furnace_active")
