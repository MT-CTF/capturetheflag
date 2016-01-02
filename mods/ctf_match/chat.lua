minetest.register_privilege("ctf_match", {
	description = "can skip matches"
})

minetest.register_chatcommand("ctf_next", {
	description = "Skip to the next match",
	privs = {
		ctf_match = true
	},
	func = function(name, param)
		ctf_match.next()
	end
})

minetest.register_chatcommand("ctf_respawn", {
	description = "Respawn a player (clean inv, send to base)",
	privs = {
		ctf_team_mgr = true
	},
	func = function(name, param)
		minetest.log("action", name .. " ran /ctf_respawn " .. param)
		local tplayer = ctf.player_or_nil(param)
		if tplayer then
			local player = minetest.get_player_by_name(param)
			if player then
				ctf.move_to_spawn(param)
				give_initial_stuff(player)
				minetest.chat_send_player(param,
					"You were sent back to base and your inventory wiped (by " .. name .. ")")
				return true, "Moved player to spawn and wiped inventory."
			else
				return false, "Player is not online."
			end
		else
			return false, "Player does not exist or is not in any teams."
		end
	end
})

local restart_on_next_match = false
local restart_on_next_match_by = nil
minetest.register_chatcommand("ctf_queue_restart", {
	description = "Queue server restart",
	privs = {
		server = true
	},
	func = function(name, param)
		restart_on_next_match = true
		restart_on_next_match_by = name
		return true, "Restart queued."
	end
})

minetest.register_chatcommand("ctf_unqueue_restart", {
	description = "Unqueue server restart",
	privs = {
		server = true
	},
	func = function(name, param)
		restart_on_next_match = false
		return true, "Restart cancelled."
	end
})

ctf_match.register_on_new_match(function()
	if restart_on_next_match then
		minetest.chat_send_player(restart_on_next_match_by, "Shutting down now!")
		minetest.request_shutdown("Restarting server at operator request.", true)
	end
end)
