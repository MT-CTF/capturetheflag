ctf_classes = {
	__classes = {},
	__classes_ordered = {},
}

dofile(minetest.get_modpath("ctf_classes") .. "/api.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/gui.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/medic.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/ranged.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/items.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/flags.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/classes.lua")


minetest.register_on_joinplayer(function(player)
	ctf_classes.update(player)

	if minetest.check_player_privs(player, { interact = true }) then
		ctf_classes.show_gui(player:get_player_name())
	end
end)

minetest.register_chatcommand("class", {
	func = function(name, params)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "You must be online to do this!"
		end

		if not ctf_classes.can_change(player) then
			return false, "Move closer to your flag to change classes!"
		end

		local cname = params:trim()
		if params == "" then
			ctf_classes.show_gui(name)
		else
			if ctf_classes.__classes[cname] then
				ctf_classes.set(player, cname)
				return true, "Set class to " .. cname
			else
				return false, "Class '" .. cname .. "' does not exist"
			end
		end
	end
})

ctf_colors.set_skin = function(player, color)
	ctf_classes.set_skin(player, color, ctf_classes.get(player))
end

ctf_classes.register_on_changed(function(player, old, new)
	if not old then
		return
	end

	local pname = player:get_player_name()
	ctf.chat_send_team(ctf.player(pname).team,
			minetest.colorize("#ABCDEF", pname .. " is now a " .. new.description))
end)
