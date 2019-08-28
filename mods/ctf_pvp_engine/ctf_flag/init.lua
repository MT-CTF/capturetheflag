-- Initialise
ctf.register_on_init(function()
	ctf.log("flag", "Initialising...")
	ctf._set("flag.allow_multiple",        true)
	ctf._set("flag.capture_take",          false)
	ctf._set("flag.names",                 true)
	ctf._set("flag.waypoints",             true)
	ctf._set("flag.protect_distance",      25)
	ctf._set("flag.nobuild_radius",        3)
	ctf._set("flag.drop_time",             7*60)
	ctf._set("flag.drop_warn_time",        60)
	ctf._set("flag.crafting",	       false)
	ctf._set("flag.alerts",                true)
	ctf._set("flag.alerts.neutral_alert",  true)
	ctf._set("gui.team.teleport_to_flag",  true)
	ctf._set("gui.team.teleport_to_spawn", false)
end)

minetest.register_privilege("ctf_place_flag", {
	description = "can place flag"
})

dofile(minetest.get_modpath("ctf_flag") .. "/hud.lua")
dofile(minetest.get_modpath("ctf_flag") .. "/gui.lua")
dofile(minetest.get_modpath("ctf_flag") .. "/flag_func.lua")
dofile(minetest.get_modpath("ctf_flag") .. "/api.lua")
dofile(minetest.get_modpath("ctf_flag") .. "/flags.lua")

ctf.register_on_new_team(function(team)
	team.flags = {}
end)

function ctf_flag.get_nearest(pos)
	local closest = nil
	local closest_distSQ = 1000000
	local pd = ctf.setting("flag.protect_distance")
	local pdSQ = pd * pd

	for tname, team in pairs(ctf.teams) do
		for i = 1, #team.flags do
			local distSQ = vector.distanceSQ(pos, team.flags[i])
			if distSQ < pdSQ and distSQ < closest_distSQ then
				closest = team.flags[i]
				closest_distSQ = distSQ
			end
		end
	end

	return closest, closest_distSQ
end

function ctf_flag.get_nearest_team_dist(pos)
	local flag, distSQ = ctf_flag.get_nearest(pos)
	if flag then
		return flag.team, distSQ
	end
end

ctf.register_on_territory_query(ctf_flag.get_nearest_team_dist)

function ctf.get_spawn(team)
	if not ctf.team(team) then
		return nil
	end

	if ctf.team(team).spawn then
		return ctf.team(team).spawn
	end

	-- Get spawn from first flag
	ctf_flag.assert_flags(team)
	if #ctf.team(team).flags > 0 then
		return ctf.team(team).flags[1]
	else
		return nil
	end
end

-- Add minimum build range
local old_is_protected = minetest.is_protected
local r = ctf.setting("flag.nobuild_radius")
local rs = r * r
function minetest.is_protected(pos, name)
	if r <= 0 or rs == 0 then
		return old_is_protected(pos, name)
	end

	local flag, distSQ = ctf_flag.get_nearest(pos)
	if flag and pos.y >= flag.y - 1 and distSQ < rs then
		minetest.chat_send_player(name,
			"Too close to the flag to build! Leave at least " .. r .. " blocks around the flag.")
		return true
	else
		return old_is_protected(pos, name)
	end
end

-- Play sound
ctf_flag.register_on_pick_up(function(attname, flag)
	local vteam = ctf.team(flag.team)
	for name, player in pairs(vteam.players) do
		minetest.sound_play({name="trumpet_lose"}, 	{
			to_player = name,
			gain = 1.0, -- default
		})
	end

	local ateam = ctf.team(ctf.player(attname).team)
	for name, player in pairs(ateam.players) do
		minetest.sound_play({name="trumpet_win"}, 	{
		    to_player = name,
		    gain = 1.0, -- default
		})
	end
end)

-- Drop after time
local pickup_times = {}
ctf_flag.register_on_pick_up(function(attname, flag)
	pickup_times[attname] = minetest.get_gametime()
end)
ctf_flag.register_on_drop(function(attname, flag)
	pickup_times[attname] = nil
end)
ctf_flag.register_on_capture(function(attname, flag)
	pickup_times[attname] = nil
end)
ctf.register_on_new_game(function()
	pickup_times = {}
end)
local function update_flag_drops()
	local time = minetest.get_gametime()
	local drop_time = ctf.setting("flag.drop_time")
	for name, start in pairs(pickup_times) do
		local remaining = drop_time - time + start
		if remaining < 0 then
			ctf_flag.player_drop_flag(name)
			minetest.chat_send_player(name, "You took too long to capture the flag, so it returned!")
		elseif remaining < ctf.setting("flag.drop_warn_time") then
			minetest.chat_send_player(name, "You have " .. remaining ..
				" seconds to capture the flag before it returns.")
		end
	end
	minetest.after(5, update_flag_drops)
end
minetest.after(5, update_flag_drops)
