vote.kick_cooldown = 600
local vlist = {} -- table storing player name, ip & lock status

minetest.register_privilege("vote_kick", {
	description = "Can (start) vote to kick a player",
	on_grant = function(name, granter)
		minetest.log("warning", "Player '" .. name .. "' has been" ..
						" granted 'vote_kick' by '" .. granter .. "'")
	end,
	on_revoke = function(name, revoker)
		minetest.log("warning", "Player '" .. name .. "' has been" ..
						" revoked of 'vote_kick' by '" .. revoker .. "'")
	end
})

minetest.register_chatcommand("vote_kick", {
	params = "<name>",
	description = "Start a vote to kick a player",
	privs = {
		interact = true,
		vote_kick = true,
	},
	func = function(name, param)
		param = param:trim()
		if param == "" then
			return false, "Please specify a player name to be vote-kicked!"
		end

		if not minetest.get_player_by_name(param) then
			return false, "There is no player called '" ..
					param .. "'"
		end

		if minetest.check_player_privs(param, {kick = true, ban = true}) then
			return false, param .. " is a moderator, and can't be kicked!"
		end

		minetest.log("warning", "Player '" .. name .. "' started a vote" ..
							" to kick '" .. param .. "'")
		return vote.new_vote(name, {
			description = "Kick " .. param,
			help = "/yes,  /no  or  /abstain",
			name = param,
			duration = 60,
			perc_needed = 0.8,

			on_result = function(self, result, results)
				if result == "yes" then
					minetest.chat_send_all("Vote passed, " ..
							#results.yes .. " to " .. #results.no .. ", " ..
							self.name .. " will be kicked.")
					minetest.kick_player(self.name,
						("The vote to kick you passed.\n You have been temporarily banned" ..
						" for %s minutes."):format(tostring(vote.kick_cooldown / 60)))
					vlist[self.name].locked = true
					minetest.after(vote.kick_cooldown, function()
						vlist[self.name] = nil
					end)
				else
					minetest.chat_send_all("Vote failed, " ..
							#results.yes .. " to " .. #results.no .. ", " ..
							self.name .. " remains ingame.")
				end
			end,

			on_vote = function(self, voter, value)
				minetest.chat_send_all(voter .. " voted " .. value .. " to '" ..
						self.description .. "'")
			end
		})
	end
})

minetest.register_chatcommand("unblock", {
	params = "<name>",
	description = "Unblock a vote-kicked player before the cooldown expires",
	privs = {kick = true, ban = true},
	func = function(name, param)
		param = param:trim()
		if param == "" then
			return false, "Please specify a player name to be unblocked!"
		end

		if not minetest.get_player_by_name(param) then
			return false, "Can't find player '" .. param .. "'"
		end

		if not vlist[name].locked then
			return false, "Failed! " .. param .. " is not blocked"
		end

		vlist[name].locked = false
		return true, param .. " has been successfully unblocked!"
	end
})

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if not vlist[name] then
		vlist[name] = {
			ip = minetest.get_player_ip(name),
			locked = false
		}
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if not vlist[name].locked then
		vlist[name] = nil
	end
end)

minetest.register_on_prejoinplayer(function(name, ip)
	if vlist[name] and vlist[name].locked then
		return "Please wait until the vote cool down period has elapsed before rejoining!"
	else
		for k, v in pairs(vlist) do
			if v.ip == ip and v.locked then
				return "This IP has been temporarily blocked."..
					" Please wait until the cool-down period has elapsed before rejoining."
			end
		end
	end
end)
