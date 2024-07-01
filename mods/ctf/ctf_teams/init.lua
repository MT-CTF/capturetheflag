ctf_teams = {
	team = {
		--[[
		tname = {
			color = "#ffffff",
			color_hex = 0x000, -- Generated from 'color' above
			irc_color = 16, -- optional, default: 16
			not_playing = false, --optional, default: false
		}
		]]
		red = {
			color = "#dc0f0f",
			color_hex = 0x000,
			irc_color = 4,
		},
		green = {
			color = "#00bb00",
			color_hex = 0x000,
			irc_color = 3,
		},
		blue = {
			color = "#0062ff",
			color_hex = 0x000,
			irc_color = 2,
		},
		orange = {
			color = "#ff4e00",
			color_hex = 0x000,
			irc_color = 8,
		},
		purple = {
			color = "#6f00a7",
			color_hex = 0x000,
			irc_color = 6,
		},
	},
	teamlist = {},

	player_team = {},
	online_players = {},
	current_team_list = {},
}

for team, def in pairs(ctf_teams.team) do
	table.insert(ctf_teams.teamlist, team)

	ctf_teams.team[team].color_hex = tonumber("0x" .. def.color:sub(2))
end

minetest.register_privilege("ctf_team_admin", {
	description = "Allows advanced team management.",
	give_to_singleplayer = false,
	give_to_admin = false,
})

ctf_core.include_files("functions.lua", "commands.lua", "register.lua")

minetest.register_on_mods_loaded(function()
	local old_join_func = minetest.send_join_message
	local old_leave_func = minetest.send_leave_message

	local function empty_func() end

	minetest.send_join_message = empty_func
	minetest.send_leave_message = empty_func

	minetest.register_on_joinplayer(function(player, last_login)
		local name = player:get_player_name()

		minetest.after(0.5, function()
			player = minetest.get_player_by_name(name)

			if not player then
				old_join_func(name, last_login)
				return
			end

			ctf_teams.allocate_player(player, true)

			local pteam = ctf_teams.get(player)

			if not pteam then
				old_join_func(player:get_player_name(), last_login)
			else
				local tcolor = ctf_teams.team[pteam].color

				minetest.chat_send_all(
					string.format(
						"*** %s joined the game.",
						minetest.colorize(tcolor, name)
					)
				)
			end
		end)
	end)

	minetest.register_on_leaveplayer(function(player, timed_out, ...)
		local pteam = ctf_teams.get(player)

		if not pteam then
			old_leave_func(player:get_player_name(), timed_out, ...)
		else
			ctf_teams.remove_online_player(player)

			local tcolor = ctf_teams.team[pteam].color

			minetest.chat_send_all(
				string.format(
					"*** %s left the game%s.",
					minetest.colorize(tcolor, player:get_player_name()),
					timed_out and " (timed out)" or ""
				)
			)
		end
	end)
end)

for team, _ in pairs(ctf_teams.team) do
	local new_chestname = string.format("ctf_teams:chest_%s", team)
	local new_doorname = string.format("ctf_teams:door_steel_%s", team)
	local old_chestname = string.format("ctf_teamitems:chest_%s", team)
	local old_doorname = string.format("ctf_teamitems:door_steel_%s", team)
	minetest.register_alias(new_chestname, old_chestname)
	minetest.register_alias(new_doorname, old_doorname)
	minetest.register_alias("ctf_teams:door_steel", "ctf_teamitems:door_steel")
end
