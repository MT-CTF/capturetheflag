local items = {
	minetest.colorize("#66a0ff", "Game Play"),
	"",
	"*  Capture an enemy's flag by walking up to it, punching it, then",
	"   running and punching your team's flag.",
	"*  Look for guns, grenades and other resources in chests.",
	"*  Guns can destroy blocks.",
	"*  Good swords do more damage than guns, but need to be used at close range.",
	"*  If the match is getting boring, type /vote, then /yes to vote yes.",
	"*  Use apples to replenish health.",
	"",

	minetest.colorize("#66a0ff", "Team Co-op"),
	"",
	"*  Your team has a chest near your flag.",
	"   Be warned that other teams can steal from it.",
	"*  Your team name is displayed in the top left.",
	"   to talk with only your team, type: /t message",
	"",

	minetest.colorize("#66a0ff", "Player Rankings"),
	"",
	"*  See the league table by typing /rankings",
	"*  See your position in it by typing /rankings me",
	"*  Get to the top by capturing lots of flags, and having a high K/D ratio.",
	"",

	minetest.colorize("#66a0ff", "Contact Moderators"),
	"",
	"*  Report people who sabotage using /report."
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

dofile(minetest.get_modpath("ctf_inventory") .. "/give_initial_stuff.lua")
