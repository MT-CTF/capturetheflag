ctf_teams = {
	team = {
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
	current_teams = {},
	current_team_list = {},
	remembered_player = {}, -- Holds players that have been set to a team previously. Format: ["player_name"] = teamname

	team_chests = {}, -- Whenever a team chest is initialized it'll be put in this table
}

for team, def in pairs(ctf_teams.team) do
	table.insert(ctf_teams.teamlist, team)

	ctf_teams.team[team].color_hex = tonumber("0x"..def.color:sub(2))
end

minetest.register_privilege("ctf_team_admin", {
	description = "Allows advanced team management.",
	give_to_singleplayer = false,
	give_to_admin = false,
})

ctf_core.include_files(
	"functions.lua",
	"commands.lua",
	"register.lua",
	"team_chest.lua",
	"team_door.lua"
)

local old_join_func = minetest.send_join_message
local old_leave_func = minetest.send_leave_message

local function empty_func() end

minetest.send_join_message = empty_func
minetest.send_leave_message = empty_func

minetest.register_on_joinplayer(function(player, ...)
	ctf_teams.allocate_player(player)

	local pteam = ctf_teams.get(player)

	if not pteam then
		old_join_func(player:get_player_name(), ...)
	else
		local tcolor = ctf_teams.team[pteam].color

		minetest.chat_send_all(string.format("*** %s joined the game.",
			minetest.colorize(tcolor, player:get_player_name())
		))
	end
end)

minetest.register_on_leaveplayer(function(player, timed_out, ...)
	local pteam = ctf_teams.get(player)

	if not pteam then
		old_leave_func(player:get_player_name(), timed_out, ...)
	else
		local tcolor = ctf_teams.team[pteam].color

		minetest.chat_send_all(string.format("*** %s left the game%s.",
			minetest.colorize(tcolor, player:get_player_name()),
			timed_out and " (timed out)" or ""
		))
	end
end)
