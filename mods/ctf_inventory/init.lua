ctf.register_on_init(function()
	ctf._set("inventory",             false)
end)

local fs = "size[8,8.5]" ..
	"bgcolor[#080808BB;true]" ..
	"background[5,5;1,1;gui_formbg.png;true]" ..
	"listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]" ..
	"list[current_player;main;0,4.25;8,1;]" ..
	"list[current_player;main;0,5.5;8,3;8]" ..
	"textlist[0,0;7.85,4;help;"

local items = {
	"Welcome to Capture the Flag!",
	"*  There is no crafting, look for stuff in chests.",
	"*  Your team color is displayed in the top left.",
	"   to talk with only your team, type: /t message",
	"*  If the match is getting boring, type /vote_next",
	"*  rubenwardy is the only admin or mod on this server.",
	"   Message him using /mail rubenwardy your message"
}
for i = 1, #items do
	if i > 1 then
		fs = fs .. ","
	end
	fs = fs .. minetest.formspec_escape(items[i])
end

	--"list[current_player;craft;1.75,0.5;3,3;]" ..
	--"list[current_player;craftpreview;5.75,1.5;1,1;]" ..
	--"image[4.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]" ..
	--"listring[current_player;main]" ..
	--"listring[current_player;craft]" ..
fs = fs ..
	"]" ..
	"image[0,4.25;1,1;gui_hb_bg.png]" ..
	"image[1,4.25;1,1;gui_hb_bg.png]" ..
	"image[2,4.25;1,1;gui_hb_bg.png]" ..
	"image[3,4.25;1,1;gui_hb_bg.png]" ..
	"image[4,4.25;1,1;gui_hb_bg.png]" ..
	"image[5,4.25;1,1;gui_hb_bg.png]" ..
	"image[6,4.25;1,1;gui_hb_bg.png]" ..
	"image[7,4.25;1,1;gui_hb_bg.png]"

minetest.register_on_joinplayer(function(player)
	if ctf.setting("inventory") then
		player:set_inventory_formspec(fs)
	end
end)
