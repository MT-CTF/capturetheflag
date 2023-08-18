local mods = minetest.get_mod_storage()
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

-- modstorage will hold the combined pre-reset rankings of all ranking resets.
-- Indexed by playername, with each name prefixed so that we can store other things alongside them without conflict
-- Resets taking place on the same month will overwrite each other
local PLAYER_RANKING_PREFIX = "rank:"

if ctf_rankings.do_reset then
	local after_timer = 0

	minetest.after(5, function()
		for mode, def in pairs(ctf_modebase.modes) do
			local top = def.rankings.top
			local time = minetest.get_us_time()
			def.rankings.op_all(function(pname, value)
				if value ~= "null" then
					local rank = minetest.parse_json(value)

					rank.place = top:get_place(pname)

					RunCallbacks(ctf_rankings.registered_on_rank_reset, pname, rank)

					if (rank.score or 0) >= 8000 and
					(rank.kills or 0) / (rank.deaths or 1) >= 1.4 and
					(rank.flag_captures or 0) >= 5 then
						rank._pro_chest = true
					end

					local current = mods:get_string(PLAYER_RANKING_PREFIX..pname)

					if current and current ~= "" then
						current = minetest.parse_json(current)

						current._last_reset = os.date("%m/%Y")
						current[os.date("%m/%Y")][mode] = rank

						mods:set_string(PLAYER_RANKING_PREFIX..pname, minetest.write_json(current))
					else
						mods:set_string(PLAYER_RANKING_PREFIX..pname, minetest.write_json({
							_last_reset = os.date("%m/%Y"),
							[os.date("%m/%Y")] = {[mode] = rank},
						}))
					end

					minetest.chat_send_all(string.format("[%s] %d: %s with %d score", mode, rank.place, pname, rank.score or 0))
				end
			end)

			after_timer = after_timer + ((minetest.get_us_time()-time) / 1e6)
			time = ((minetest.get_us_time()-time) / 1e6).."s"

			minetest.chat_send_all("Saved old rankings for mode "..mode..". Took "..time)
			minetest.log("action", "Saved old rankings for mode "..mode..". Took "..time)
		end

		for mode, def in pairs(ctf_modebase.modes) do
			local time = minetest.get_us_time()
			def.rankings.op_all(function(pname, value)
				def.rankings:del(pname)

				minetest.chat_send_all(string.format("[%s] Reset rankings of player %s", mode, pname))
			end)

			after_timer = after_timer + ((minetest.get_us_time()-time) / 1e6)
			time = ((minetest.get_us_time()-time) / 1e6).."s"

			minetest.chat_send_all("Reset rankings for mode "..mode..". Took "..time)
			minetest.log("action", "Reset rankings for mode "..mode..". Took "..time)
		end

		mods:set_int("_do_reset", 0)
		mods:set_int("_current_reset", mods:get_int("_current_reset") + 1)
		minetest.request_shutdown("Ranking reset done. Thank you for your patience", true, after_timer + 5)
	end)
end

if mods:get_int("_reset_date") ~= 0 and os.date("*t", mods:get_int("_reset_date")).month == os.date("*t").month then
	local CHECK_INTERVAL = 60 * 50 -- 50 minutes
	local timer = CHECK_INTERVAL
	minetest.register_globalstep(function(dtime)
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
					elseif hours_left == 1 then
						ctf_report.send_report("[RANKING RESET] The queued ranking reset will happen in 1 hour")

						CHECK_INTERVAL = (61 - current.min) * 60

						minetest.chat_send_all(minetest.colorize("red",
							"[RANKING RESET] There will be a ranking reset in " .. CHECK_INTERVAL ..
							" minutes. The server will restart twice during the reset process"
						))
					end
				else
					mods:set_int("_do_reset", 1)
					mods:set_int("_reset_date", 0)
					ctf_rankings.do_reset = true

					minetest.registered_chatcommands["queue_restart"].func("[RANKING RESET]",
						"There will be another restart once the ranking reset is done."
					)
				end
			end
		end
	end)
end

local confirm = {}
minetest.register_chatcommand("queue_ranking_reset", {
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
					minetest.colorize("cyan", "/queue_ranking_reset <yes|no>") ..
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
