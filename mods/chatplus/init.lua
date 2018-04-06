-- Chat Plus
--    by rubenwardy
---------------------
-- init.lua
-- Three handlers: ignoring, distance, and mail.
---------------------

dofile(minetest.get_modpath("chatplus") .. "/api.lua")

--
-- Ignoring
--
chatplus.register_handler(function(from, to, msg)
	if chatplus.players[to] and chatplus.players[to].ignore and chatplus.players[to].ignore[from] then
		return false
	end
	return nil
end)

minetest.register_chatcommand("ignore", {
	params = "name",
	description = "ignore: Ignore a player",
	func = function(name, param)
		chatplus.poke(name)
		if not chatplus.players[name].ignore[param] then
			chatplus.players[name].ignore[param] = true
			minetest.chat_send_player(name, param .. " has been ignored")
			chatplus.save()
		else
			minetest.chat_send_player(name, "Player " .. param .. " is already ignored.")
		end
	end
})

minetest.register_chatcommand("unignore", {
	params = "name",
	description = "unignore: Unignore a player",
	func = function(name, param)
		chatplus.poke(name)
		if chatplus.players[name].ignore[param] then
			chatplus.players[name].ignore[param] = false
			minetest.chat_send_player(name, param .. " has been unignored")
			chatplus.save()
		else
			minetest.chat_send_player(name, "Player " .. param .. " is already unignored.")
		end
	end
})



--
-- Distance
--
chatplus.register_handler(function(from, to, msg)
	local d = chatplus.setting("distance")
	if d <= 0 then
		return nil
	end

	local from_o = minetest.get_player_by_name(from)
	local to_o = minetest.get_player_by_name(to)
	if not from_o or not to_o then
		return nil
	end

	return not d or vector.distance(from_o:getpos(), to_o:getpos()) <= tonumber(d)
end)



--
-- Bad words
--
chatplus.register_handler(function(from,to,msg)
	local words = chatplus.setting("badwords"):split(",")
	for _,v in pairs(words) do
		if (v:trim()~="") and ( msg:find(v:trim(), 1, true) ~= nil ) then
			minetest.chat_send_player(from, "Swearing is banned")
			return false
		end
	end
	return nil
end)



--
-- Highlighted PMs
--
minetest.registered_chatcommands["msg"].func = function(name, param)
	local sendto, message = param:match("^(%S+)%s(.+)$")
	if not sendto then
		return false, "Invalid usage, see /help msg."
	end
	if not minetest.get_player_by_name(sendto) then
		return false, "The player " .. sendto
				.. " is not online."
	end
	minetest.log("action", "PM from " .. name .. " to " .. sendto
			.. ": " .. message)
	minetest.chat_send_player(sendto, minetest.colorize("#00FF55",
		"PM from " .. name .. ": " .. message))
	return true, "Message sent."
end
