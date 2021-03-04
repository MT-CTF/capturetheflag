-- Licensed under the MIT license, written by appgurueu.
local players = {}
local blocks_per_second = 5
local resend_chat_message_seconds = 10

minetest.register_on_joinplayer(function(player)
	-- player has to wait after join before they can place a node
	players[player:get_player_name()] = {
		last_placement = minetest.get_us_time(),
		last_chat_message_sent = -math.huge
	}
end)

local chat_send_player = minetest.chat_send_player
function minetest.chat_send_player(name, message)
	if players[name] then
		players[name].last_chat_message_sent = -math.huge
	end
	return chat_send_player(name, message)
end

local chat_send_all = minetest.chat_send_all
function minetest.chat_send_all(message)
	for _, playerdata in pairs(players) do
		playerdata.last_chat_message_sent = -math.huge
	end
	return chat_send_all(message)
end

minetest.register_on_leaveplayer(function(player)
	players[player:get_player_name()] = nil
end)

minetest.register_on_placenode(function(pos, _newnode, placer, oldnode, _itemstack, pointed_thing)
	if not ItemStack(minetest.get_node(pointed_thing.under).name):get_definition().pointable then
		-- this should happen rarely
		minetest.chat_send_player(placer:get_player_name(), "The block you have been building to has been dug/replaced!")
		minetest.set_node(pos, oldnode)
		return true
	end
	local name = placer:get_player_name()
	local playerdata = players[name]
	local time = minetest.get_us_time()
	if (time - playerdata.last_placement) / 1e6 < 1 / blocks_per_second then
		if (time - playerdata.last_chat_message_sent) / 1e6 >= resend_chat_message_seconds then
			chat_send_player(placer:get_player_name(), "You are placing blocks too fast (more than " .. blocks_per_second .. " blocks per second) !")
			playerdata.last_chat_message_sent = time
		end
		minetest.set_node(pos, oldnode)
		return true
	end
	playerdata.last_placement = time
end)
