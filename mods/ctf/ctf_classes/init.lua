ctf_classes = {
	__classes = {},
	__classes_ordered = {},
}

dofile(minetest.get_modpath("ctf_classes") .. "/api.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/gui.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/medic.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/ranged.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/melee.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/items.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/flags.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/classes.lua")


minetest.register_on_joinplayer(function(player)
	ctf_classes.update(player)

	if ctf_classes.can_change(player) and
			minetest.check_player_privs(player, { interact = true }) then
		ctf_classes.show_gui(player:get_player_name(), player)
	end
end)

minetest.register_chatcommand("class", {
	func = function(name, params)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "You must be online to do this!"
		end

		local can_change, reason = ctf_classes.can_change(player)
		if not can_change then
			return false, reason
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

local old_set_skin = ctf_colors.set_skin
ctf_colors.set_skin = function(player, color, ...)
	if color == "blue" or color == "red" then
		player:set_properties({
			textures = {"ctf_classes_skin_" .. ctf_classes.get(player).name .. "_" .. (color or "blue") .. ".png"}
		})
	elseif color then
		old_set_skin(player, color, ...)
	end
end
ctf_classes.set_skin = ctf_colors.set_skin

ctf_classes.register_on_changed(function(player, old, new)
	if not old then
		return
	end

	local pname = player:get_player_name()
	ctf.chat_send_team(ctf.player(pname).team,
			minetest.colorize("#ABCDEF", pname .. " is now a " .. new.description))
end)

local old_get_damage_modifier = ctf.get_damage_modifier
function ctf.get_damage_modifier(player, tool_capabilities)
	local modifier = 0
	if tool_capabilities.damage_groups.sword then
		local class = ctf_classes.get(player)
		if class.properties.sword_modifier then
			modifier = class.properties.sword_modifier
		end
	end

	return modifier + old_get_damage_modifier(player, tool_capabilities)
end
