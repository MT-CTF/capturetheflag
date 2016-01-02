ctf_match.registered_on_skip_map = {}
function ctf_match.register_on_skip_map(func)
	if ctf._mt_loaded then
		error("You can't register callbacks at game time!")
	end
	table.insert(ctf_match.registered_on_skip_map, func)
end

function ctf_match.vote_next(name, params)
	return vote.new_vote(name, {
		description = "Skip to next match",
		help = "/yes,  /no  or  /abstain",
		duration = 60,
		perc_needed = 0.5,
		unanimous = 5,

		on_result = function(self, result, results)
			if result == "yes" then
				minetest.chat_send_all("Vote to skip match passed, " ..
						#results.yes .. " to " .. #results.no)
				for i = 1, #ctf_match.registered_on_skip_map do
					ctf_match.registered_on_skip_map[i]()
				end
				ctf_match.next()
			else
				minetest.chat_send_all("Vote to skip match failed, " ..
						#results.no .. " to " .. #results.yes)
			end
		end,

		on_vote = function(self, name, value)
			minetest.chat_send_all(name .. " voted " .. value .. " to '" ..
					self.description .. "'")
		end
	})
end

minetest.register_chatcommand("vote", {
	privs = {
		interact = true
	},
	func = ctf_match.vote_next
})

minetest.register_on_chat_message(function(name, msg)
	if msg == "/vote_next" then
		local suc, msg = ctf_match.vote_next(name)
		if msg then
			minetest.chat_send_player(name, msg)
		end
		return true
	end
end)
