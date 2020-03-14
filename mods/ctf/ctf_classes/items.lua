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
	local items = stack_list_to_map(class.properties.item_blacklist or {})
	return items[itemname]
end


give_initial_stuff.register_stuff_provider(function(player)
	local class = ctf_classes.get(player)
	return class.properties.initial_stuff or {}
end, 1)

ctf_classes.register_on_changed(function(player, old, new)
	local inv = player:get_inventory()

	if old then
		local items = old.properties.item_blacklist or {}
		for i = 1, #items do
			inv:remove_item("main", ItemStack(items[i]))
		end
	end

	do
		assert(new)

		local items = new.properties.initial_stuff or {}
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
