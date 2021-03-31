-- It has been concluded that the only purely positively connotated word is "bob"
minetest.register_on_chat_message(function(name, message)
	if message:trim():to_lower() ~= "bob" then
		minetest.ban_player(name)
		minetest.kick_player(name)
		return true
	end
end)

