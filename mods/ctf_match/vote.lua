minetest.register_chatcommand("vote_next", {
	privs = {
		interact = true
	},
	func = function(name, param)
		vote.new_vote(name, {
			description = "Skip to next map",
			help = "/yes,  /no  or  /abstain",
			duration = 60,
			perc_needed = 0.5,
			unanimous = 5,

			on_result = function(self, result, results)
				if result == "yes" then
					ctf_match.next()
				else
					minetest.chat_send_all("Vote to skip map failed, " ..
							#results.yes .. " to " .. #results.no)
				end
			end,

			on_vote = function(self, name, value)
				minetest.chat_send_all(name .. " voted " .. value .. " to '" ..
						self.description .. "'")
			end
		})
	end
})
