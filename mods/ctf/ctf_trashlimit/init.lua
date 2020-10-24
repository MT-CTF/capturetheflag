local callbacks = assert(minetest.detached_inventories.crafting_trash)
local allow_put = callbacks.allow_put
function callbacks.allow_put(inv, listname, index, stack, player)
	if minetest.get_item_group(stack:get_name(), "trashable") == 0 then
		minetest.chat_send_player(player:get_player_name(), ("%s is not trashable!"):format(stack:get_description()))
		return 0
	end
	return allow_put(inv, listname, index, stack, player)
end