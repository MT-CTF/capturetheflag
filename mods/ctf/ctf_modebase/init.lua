ctf_modebase = {
	-- Table containing all registered modes and their definitions
	modes                = {},    ---@type table

	-- Same as ctf_modebase.modes but in list form
	modelist             = {},    ---@type list

	-- Name of the mode currently being played. On server start this will be false
	current_mode         = false, ---@type string

	-- Players can hit, heal, etc
	match_started         = false, ---@type boolean

	-- For team allocator
	in_game               = false, ---@type boolean

	-- Get the mode def of the current mode. On server start this will return false
	get_current_mode = function(self)
		return self.current_mode and self.modes[self.current_mode]
	end,

	-- Amount of matches played since this mode won the last vote
	current_mode_matches_played = 0, ---@type integer

	-- How many matches will be played for the current mode
	current_mode_matches        = 5, ---@type integer

	-- taken_flags[Player Name] = list of team names
	taken_flags          = {},

	-- team_flag_takers[Team name][Player Name] = list of team names
	team_flag_takers     = {},

	-- flag_taken[Team Name] = Name of thief
	flag_taken           = {},

	--flag_captured[Team name] = true if captured, otherwise nil
	flag_captured        = {},
}

ctf_gui.old_init()

function ctf_modebase.announce(msg)
end

ctf_core.include_files(
	"register.lua",
	"map_catalog.lua",
	"map_catalog_show.lua",
	"ranking_commands.lua",
	"summary.lua",
	"player.lua",
	"immunity.lua",
	"treasure.lua",
	"flags/nodes.lua",
	"flags/taking.lua",
	"flags/huds.lua",
	"match.lua",
	"crafting.lua",
	"hpregen.lua",
	"respawn_delay.lua",
	"markers.lua",
	"bounties.lua",
	"build_timer.lua",
	"update_wear.lua",
	"mode_vote.lua",
	"skip_vote.lua",
	"recent_rankings.lua",
	"bounty_algo.lua",
	"features.lua"
)

minetest.register_on_mods_loaded(function()
	table.sort(ctf_modebase.modelist)
	if ctf_core.settings.server_mode == "play" then
		minetest.after(1, ctf_modebase.start_new_match)
	end

	for _, name in pairs(ctf_modebase.modelist) do
		ctf_settings.register("ctf_modebase:default_vote_"..name, {
			type = "list",
			description = "Match count vote for the mode '"..HumanReadable(name).."'",
			list = {HumanReadable(name).." - Ask", "0", "1", "2", "3", "4", "5"},
			_list_map = {"ask", 0, 1, 2, 3, 4, 5},
			default = "1", -- "Ask"
		})
	end
end)

minetest.override_chatcommand("pulverize", {
	privs = {creative = true},
})
