ctf_match.registered_on_skip_map = {}
function ctf_match.register_on_skip_map(func)
	if ctf._mt_loaded then
		error("You can't register callbacks at game time!")
	end
	table.insert(ctf_match.registered_on_skip_map, func)
end

function skip()
	for i = 1, #ctf_match.registered_on_skip_map do
		ctf_match.registered_on_skip_map[i]()
	end
	ctf_match.next()
end

local can_vote_skip = false
local voted_skip = false
local flags_hold = 0
function ctf_match.vote_next(name)
	local tcolor = ctf_colors.get_color(ctf.player(name)).css or "#FFFFFFFF"
	minetest.chat_send_all(minetest.colorize("#FFAA11", "Vote started by ") ..
		minetest.colorize(tcolor, name))

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

				can_vote_skip = false
				voted_skip = true
				if flags_hold <= 0 then
					skip()
				end
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

-- Automatically start a skip vote after 90m, and subsequent votes every 15m

local matchskip_time
local matchskip_timer = 0
minetest.register_globalstep(function(dtime)
	if not can_vote_skip then return end

	matchskip_timer = matchskip_timer + dtime

	if matchskip_timer > matchskip_time then
		matchskip_timer = 0

		-- Start vote and decrease time until next vote skip
		ctf_match.vote_next("[CTF automatic skip-vote]"..matchskip_time)
		matchskip_time = tonumber(minetest.settings:get("ctf_match.auto_skip_interval")) or 15 * 60
	end
end)

ctf.register_on_new_game(function()
	can_vote_skip = false
	voted_skip = false
	flags_hold = 0
end)
ctf_flag.register_on_pick_up(function()
	flags_hold = flags_hold + 1
end)
ctf_flag.register_on_drop(function()
	flags_hold = flags_hold - 1
	if voted_skip and flags_hold <= 0 then
		minetest.after(5, function()
			skip()
		end)
	end
end)

ctf_match.register_on_build_time_end(function()
	can_vote_skip = true
	matchskip_timer = 0
	-- Set to initial vote time
	matchskip_time = tonumber(minetest.settings:get("ctf_match.auto_skip_delay")) or 50 * 60
end)
