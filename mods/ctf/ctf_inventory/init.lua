 color = "#66A0FF"
local items = {
	"",
	color .. "Game Play",
	"",
	"*  Capture an enemy's flag by walking up to it, punching it, then",
	"   running and punching your team's flag.",
	"*  Look for weapons and other resources in chests, or mine and use furnaces to make swords.",
	"*  Good swords do more damage than guns, but need to be used at close range.",
	"*  Use medkits to replenish health gradually.",
	"*  Gain more score by killing more than you die, or by capturing the flag.",
	"*  Players are immune for 5 seconds after they respawn.",
	"*  Access the pro section of the chest by achieving 2k+ score,",
	"   killing 3 people for every 2 deaths, and capturing the flag at least 10 times",
	"",

	color .. "Team Co-op",
	"",
	"*  Your team has a chest near your flag.",
	"*  Your team name is displayed in the top left.",
	"   to talk with only your team, type: /t message",
	"",

	color .. "Player Rankings",
	"",
	"*  See the league table by typing /rankings",
	"*  See your position in it by typing /rankings me",
	"*  Get to the top by capturing lots of flags, and having a high K/D ratio.",
	"",

	color .. "Contact Moderators",
	"",
	"*  Report people using /report or the #reports channel in Discord",

	color .. "Other",
	"",
	"* CaptureTheFlag Discord: https://discord.gg/vcZTRPX",
}
for i = 1, #items do
	items[i] = minetest.formspec_escape(items[i])
end

local fs = [[
		textlist[0,0;7.85,8.5;help;
	]] .. table.concat(items, ",") .. "]"

sfinv.register_page("ctf_inventory:help", {
	title = "Help",
	get = function(self, player, context)
		return sfinv.make_formspec(player, context, fs, false)
	end
})
