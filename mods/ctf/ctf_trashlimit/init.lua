minetest.unregister_chatcommand("pulverize")
minetest.unregister_chatcommand("clearinv")

local callbacks = assert(minetest.detached_inventories.crafting_trash)
local allow_put = callbacks.allow_put
function callbacks.allow_put(inv, listname, index, stack, player)
	local itemname = stack:get_name()
	if minetest.get_item_group(itemname, "trashable") == 0 and not ctf_classes.item_is_class_blacklisted(player, itemname) then
		minetest.chat_send_player(player:get_player_name(), ("%s is not trashable!"):format(stack:get_description()))
		return 0
	end
	return allow_put(inv, listname, index, stack, player)
end