function ctf_colors.get_color(tplayer)
	local team = ctf.team(tplayer.team)
	local tcolor_text = nil
	if team then
		tcolor_text = team.data.color
	end
	local tcolor_hex = ctf.flag_colors[tcolor_text]
	if not tcolor_hex then
		tcolor_hex = "0x000000"
	end

	local tcolor_css = "#" .. tcolor_hex:sub(3, 8)

	return {
		text = tcolor_text,
		hex = tcolor_hex,
		css = tcolor_css
	}
end

function ctf_colors.get_irc_color(tplayer)
	local team = ctf.team(tplayer.team)
	local tcolor_text = nil
	if team then
		tcolor_text = team.data.color
	end
	return ctf_colors.irc_colors[tcolor_text]
end

function ctf_colors.get_nametag_color(name, tplayer, tcolor_text, tcolor_hex)
	if ctf.setting("colors.nametag.tcolor") then
		return "0xFF" .. string.sub(tcolor_hex, 3)
	else
		return "0xFFFFFFFF"
	end
end

function ctf_colors.set_skin(player, color)
	if minetest.global_exists("armor") then
		-- TODO: how should support for skin mods be done?
		armor.textures[name].skin = "ctf_colors_skin_" .. color .. ".png"
		armor:update_player_visuals(player)
	else
		player:set_properties({
			textures = {"ctf_colors_skin_" .. color .. ".png"}
		})
	end
end

function ctf_colors.update(player, name, tplayer)
	if not player then
		player = minetest.get_player_by_name(name)
	end

	local tcolor = ctf_colors.get_color(tplayer)

	if ctf.setting("colors.hudtint") then
		if tcolor.text == "red" or tcolor.text == "blue" then
			player:hud_set_hotbar_image("ctf_colors_hotbar_" .. tcolor.text .. ".png")
			player:hud_set_hotbar_selected_image("ctf_colors_hotbar_selected_" .. tcolor.text .. ".png")
		else
			ctf.error("ctf_colors", "Hint color not supported for " .. tcolor.text)
		end
	end

	if ctf.setting("colors.skins") and tcolor.text then
		ctf_colors.set_skin(player, tcolor.text)
	end

	if ctf.setting("hud.teamname") then
		if not ctf.hud:exists(player, "ctf:hud_team") then
			ctf.hud:add(player, "ctf:hud_team", {
				hud_elem_type = "text",
				position      = {x = 1, y = 0},
				scale         = {x = 100, y = 100},
				text          = "Team " .. tplayer.team,
				number        = tcolor.hex,
				offset        = {x = -20, y = 20},
				alignment     = {x = -1, y = 0}
			})
		else
			ctf.hud:change(player, "ctf:hud_team", "text", "Team " .. tplayer.team)
			ctf.hud:change(player, "ctf:hud_team", "number", tcolor.hex)
		end
	end
end

ctf.hud.register_part(ctf_colors.update)
