--[[
if #msg > 200 then
	local warn = warned[from] or { count = 0 }
	warned[from] = warn
	warn.count = warn.count + 1
	warn.time = minetest.get_gametime()

	if warn.count > 3 then
		if been_kicked[from] then
			minetest.kick_player(from, "Too long chat message! ")
			been_kicked =
		else
			minetest.kick_player(from, "Too long chat message! Next time is temp-ban.")
			been_kicked
		end
		return true
	else
		minetest.chat_send_player(from, "That chat message was rather long! " ..
			(2 - warn.count) .. " warnings remaining.")
	end
end
]]
