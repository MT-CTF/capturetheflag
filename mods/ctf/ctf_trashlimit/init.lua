minetest.unregister_chatcommand("pulverize")
minetest.unregister_chatcommand("clearinv")

local callbacks = assert(minetest.detached_inventories.crafting_trash)
local allow_put = callbacks.allow_put
function callbacks.allow_put(inv, listname, index, stack, player)
	local name = player:get_player_name()
	local chest_pos = ctf_map.chest_locations[ctf.player(name).team]
	if chest_pos and vector.distance(player:get_pos(), chest_pos) > 5 then
		minetest.chat_send_player(name, "Move closer to your team chest to trash items!")
		return 0
	end
	if not ctf_stats.is_pro(name) then
		return 0
	end
	local itemname = stack:get_name()
	if minetest.get_item_group(itemname, "trashable") == 0 and not ctf_classes.item_is_class_blacklisted(player, itemname) then
		minetest.chat_send_player(name, ("%s is not trashable!"):format(stack:get_description()))
		return 0
	end
	return allow_put(inv, listname, index, stack, player)
end