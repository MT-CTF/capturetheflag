ctf_match.registered_on_skip_map = {}
function ctf_match.register_on_skip_map(func)
	if ctf._mt_loaded then
		error("You can't register callbacks at game time!")
	end
	table.insert(ctf_match.registered_on_skip_map, func)
end

function ctf_match.vote_next(name)
	local tcolor = ctf_colors.get_color(ctf.player(name)).css or "#FFFFFFFF"
	minetest.chat_send_all(minetest.colorize("#FFAA11", "Vote started by ") ..
		minetest.colorize(tcolor, name))

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

local same_match = true
local function auto_vote(interval)
	-- If not same match, set it to true and return
	if not same_match then
		same_match = true
		return
	end

	-- Start vote
	ctf_match.vote_next("[CTF automatic skip-vote]")

	-- Recursively call the same function after `interval` seconds
	minetest.after(interval, auto_vote, interval)
end

local function disable_auto_vote()
	-- At the end of a match, set same_match to false to disable auto_vote
	same_match = false
end
ctf_match.register_on_winner(disable_auto_vote)
ctf_match.register_on_skip_map(disable_auto_vote)

-- Automatically start a skip vote after 90m, and subsequent votes every 15m
ctf_match.register_on_build_time_end(function()
	local delay    = tonumber(minetest.settings:get("ctf_match.auto_skip_delay"))    or 30 * 120
	local interval = tonumber(minetest.settings:get("ctf_match.auto_skip_interval")) or 30 *  15
	minetest.after(delay, auto_vote, interval)
end)
