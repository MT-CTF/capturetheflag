ctf_match.registered_on_skip_match = {}
function ctf_match.register_on_skip_match(func)
	if ctf._mt_loaded then
		error("You can't register callbacks at game time!")
	end
	table.insert(ctf_match.registered_on_skip_match, func)
end

function ctf_match.vote_next(name, params)
	if minetest.global_exists("irc") then
		local tname = ctf.player(name).team or "none"
		irc:say("Vote started by " .. name .. " (team " .. tname .. ")")
	end

	return vote.new_vote(name, {
		description = "Skip to next match",
		help = "/yes,  /no  or  /abstain",
		duration = 60,
		perc_needed = 0.6,
		unanimous = 5,

		on_result = function(self, result, results)
			if result == "yes" then
				minetest.chat_send_all("Vote to skip match passed, " ..
						#results.yes .. " to " .. #results.no)
				for i = 1, #ctf_match.registered_on_skip_match do
					ctf_match.registered_on_skip_match[i]()
				end
				ctf_match.next()
			else
				minetest.chat_send_all("Vote to skip match failed, " ..
						#results.no .. " to " .. #results.yes)
			end
		end,

		on_vote = function(self, voter, value)
			minetest.chat_send_all(voter .. " voted " .. value .. " to '" ..
					self.description .. "'")
		end
	})
end

ctf_match.register_on_new_match(vote.clear_vote)

minetest.register_chatcommand("vote", {
	privs = {
		interact = true,
		vote_starter = true
	},
	func = ctf_match.vote_next
})

minetest.register_on_chat_message(function(name, msg)
	if msg == "/vote_next" and minetest.check_player_privs(name,
			{interact=true, vote_starter=true}) then
		local _, vmsg = ctf_match.vote_next(name)
		if vmsg then
			minetest.chat_send_player(name, vmsg)
		end
		return true
	end
end)
