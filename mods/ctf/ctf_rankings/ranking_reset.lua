local mods = core.get_mod_storage()
--[[
{
	_reset_date = <os.time() output>, -- 0 if no reset is queued
	_do_reset = <(int) 1 | 0>, -- set to 1 when it's time to reset
	_current_reset = 0, -- Incremented by 1 every time a reset is done
	_current_reset_date = os.date("%m/%Y"), -- Set every time rankings are reset

	["<PLAYER_RANKING_PREFIX>:<pname>"] = {
		_last_reset = os.date("%m/%Y"),
		[os.date("%m/%Y")] = {[mode] = rank, ...},
		...
	},
	...
}
--]]

ctf_rankings.current_reset = mods:get_int("_current_reset")
ctf_rankings.do_reset = mods:get_int("_do_reset") == 1
-- Resets taking place on the same month will overwrite each other

local function do_reset()
	for mode, def in pairs(ctf_modebase.modes) do
		local output = {}
		for place, player in ipairs(def.rankings:get_top(0, "score")) do
			player = player and player[1]
			if player then
				local rankings = def.rankings:get(player)

				rankings.place = place
				rankings._place = place
				rankings._playername = player

				if (rankings.score or 0) >= 8000 and
				(rankings.kills or 0) / (rankings.deaths or 1) >= 1.4 and
				(rankings.flag_captures or 0) >= 5 then
					rankings._pro_chest = os.time()
				end

				if rankings._pro_chest then
					mods:set_string("pro_chest:"..player, os.time())
				end

				RunCallbacks(ctf_rankings.registered_on_rank_reset, player, table.copy(rankings), mode)

				output[place] = rankings
			end
		end

		local savefile = io.open(core.get_worldpath().."/backup-"..mode.."-"..os.date("%Y").."-"..os.date("%m")..".json", "w")
		savefile:write(core.write_json(output))
		savefile:close()
	end

	ctf_modebase.modes.classic.rankings:__flushdb()

	mods:set_int("_do_reset", 0)
	mods:set_int("_current_reset", mods:get_int("_current_reset") + 1)

	core.request_shutdown("Ranking reset done. Thank you for your patience", true, 5)
end


if ctf_rankings.do_reset then
	core.after(0, do_reset)
end

if mods:get_int("_reset_date") ~= 0 and os.date("*t", mods:get_int("_reset_date")).month == os.date("*t").month then
	local CHECK_INTERVAL = 60 * 30 -- 30 minutes
	local timer = CHECK_INTERVAL
	core.register_globalstep(function(dtime)
		timer = timer + dtime

		if timer >= CHECK_INTERVAL and not ctf_rankings.do_reset then
			timer = 0

			local goal = os.date("*t", mods:get_int("_reset_date"))
			local current = os.date("*t")

			if current.year >= goal.year and current.month >= goal.month and current.day >= goal.day then
				local hours_left = goal.hour - current.hour

				if hours_left > 0 then
					if hours_left == 6 then
						ctf_report.send_report("[RANKING RESET] The queued ranking reset will happen in ~6 hours")
						core.chat_send_all("[RANKING RESET] The queued ranking reset will happen in ~6 hours")
					elseif hours_left == 1 then
						ctf_report.send_report("[RANKING RESET] The queued ranking reset will happen in 1 hour")
						core.chat_send_all("[RANKING RESET] The queued ranking reset will happen in 1 hour")

						CHECK_INTERVAL = (61 - current.min) * 60

						core.chat_send_all(core.colorize("red",
							"[RANKING RESET] There will be a ranking reset in " .. CHECK_INTERVAL ..
							" minutes. The server will restart twice during the reset process"
						))
					end
				else
					mods:set_int("_do_reset", 1)
					mods:set_int("_reset_date", 0)
					ctf_rankings.do_reset = true

					core.registered_chatcommands["queue_restart"].func("[RANKING RESET]",
						"Ranking Reset"
					)
				end
			end
		end
	end)
end

local confirm = {}
core.register_chatcommand("queue_ranking_reset", {
	description = "Queue a ranking reset. Will reset all rankings to 0",
	params = "<day 1-31> <month 1-12> [year e.g 2042] [hour 0-23] | <yes|no|unqueue|status>",
	privs = {server = true},
	func = function(name, params)
		if params == "unqueue" then
			confirm[name] = nil
			mods:set_int("_reset_date", 0)

			return true, "Ranking Reset unqueued"
		end

		if params:match("^stat") then
			local date = mods:get_int("_reset_date")

			if date ~= 0 then
				return true, "Ranking reset queued for "..os.date("%a %d, %b %Y at %I:%M %p", date)
			else
				return true, "There is no ranking reset queued"
			end
		end

		if not confirm[name] then
			params = string.split(params, "%s", false, 3, true)

			local day, month, year, hour = params[1], params[2], params[3], params[4]

			if not day or not month then
				return false
			end

			hour  = math.min(math.max(tonumber( hour  or 7), 0), 23)
			day   = math.min(math.max(tonumber( day       ), 1), 31)
			month = math.min(math.max(tonumber( month     ), 1), 12)
			year  = math.max(tonumber(year or os.date("%Y")), tonumber(os.date("%Y")))

			if type(day) ~= "number" or type(month) ~= "number" or type(year) ~= "number" or type(hour) ~= "number" then
				return false, "Please supply numbers for the day/month/year/hour"
			end

			confirm[name] = os.time({day = day, month = month, year = year, hour = hour})

			return true, "Please run " ..
					core.colorize("cyan", "/queue_ranking_reset <yes|no>") ..
					" to confirm/deny the date: " ..
					os.date("%a %d, %b %Y at %I:%M %p", confirm[name])
		else
			if params:match("yes") then
				local date = os.date("%a %d, %b %Y at %I:%M %p", confirm[name])

				mods:set_int("_reset_date", confirm[name])

				confirm[name] = nil

				return true, "Ranking reset queued for "..date
			else
				confirm[name] = nil

				return true, "Aborted"
			end
		end
	end,
})
