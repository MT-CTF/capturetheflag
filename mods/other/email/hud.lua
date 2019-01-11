local hudkit = dofile(minetest.get_modpath("email") .. "/hudkit.lua")
email.hud = hudkit()
function email.update_hud(player)
	local name = player:get_player_name()
	local inbox = email.get_inbox(name)

	if inbox and #inbox > 0 then
		if email.hud:exists(player, "email:text") then
			email.hud:change(player, "email:text", "text", #inbox .. " /inbox")
		else
			email.hud:add(player, "email:icon", {
				hud_elem_type = "image",
				name = "MailIcon",
				position = {x=0.52, y=0.52},
				text="email_mail.png",
				scale = {x=1,y=1},
				alignment = {x=0.5, y=0.5},
			})

			email.hud:add(player, "email:text", {
				hud_elem_type = "text",
				name = "MailText",
				position = {x=0.55, y=0.52},
				text= #inbox .. " /inbox",
				scale = {x=1,y=1},
				alignment = {x=0.5, y=0.5},
			})
		end
	else
		email.hud:remove(player, "email:icon")
		email.hud:remove(player, "email:text")
	end
end
minetest.register_on_leaveplayer(function(player)
	email.hud.players[player:get_player_name()] = nil
end)
function email.update_all_hud()
	local players = minetest.get_connected_players()
	for _, player in pairs(players) do
		email.update_hud(player)
	end
	minetest.after(5, email.update_all_hud)
end
minetest.after(5, email.update_all_hud)
