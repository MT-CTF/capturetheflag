local fs = [[
	size[8,8.6]
	bgcolor[#080808BB;true]
	background[5,5;1,1;gui_formbg.png;true]
	{{ nav }}
	textlist[0,0;7.85,8.5;help;
]]

local items = {
	"Tips",
	"",
	"*  Capture an enemy's flag by walking up to it, punching it,",
	"   then running and punching your team's flag.",
	"*  Look for guns, grenades and other resources in chests.",
	"*  Guns can destroy blocks.",
	"*  See the league table by typing /rankings",
	"   See your position in it by typing /rankings me",
	"   Get to the top by capturing lots of flags, and having a high K/D ratio.",
	"*  Your team has a chest near your flag.",
	"   Be warned that other teams can steal from it.",
	"*  Your team name is displayed in the top left.",
	"   to talk with only your team, type: /t message",
	"*  If the match is getting boring, type /vote, then /yes to vote yes.",
	"*  Report people who sabotage using /report."
}
for i = 1, #items do
	items[i] = minetest.formspec_escape(items[i])
end
fs = fs .. table.concat(items, ",") .. "]"

sfinv.register_page("ctf_inventory:help", {
	title = "Help",
	get = function(player, context)
		return fs
	end
})


minetest.register_on_joinplayer(function(player)
	if ctf.setting("inventory") then
		player:set_inventory_formspec(fs)
	end
end)

dofile(minetest.get_modpath("ctf_inventory") .. "/give_initial_stuff.lua")
