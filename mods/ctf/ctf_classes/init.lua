ctf_classes = {
	__classes = {},
	__classes_ordered = {},
}

dofile(minetest.get_modpath("ctf_classes") .. "/api.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/gui.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/regen.lua")

ctf_classes.register("knight", {
	description = "Knight",
	pros = { "+10 HP", "+10% melee skill" },
	cons = { "-10% speed" },
	max_hp = 30,
	color = "#ccc",
})

ctf_classes.register("shooter", {
	description = "Shooter",
	pros = { "+10% ranged skill", "Can use sniper rifles", "Can use grapling hooks" },
	cons = {},
	speed = 1.1,
	color = "#c60",
})

ctf_classes.register("medic", {
	description = "Medic",
	speed = 1.1,
	pros = { "x2 regen for nearby friendlies", "Free bandages" },
	cons = { "Can't capture the flag"},
	color = "#0af",
})

minetest.register_on_joinplayer(ctf_classes.update)

minetest.register_chatcommand("class", {
	func = function(name, params)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "You must be online to do this!"
		end

		if not ctf_classes.can_change(player) then
			return false, "Move closer to the flag to change classes!"
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

local flags = {
	"ctf_flag:flag",
	"ctf_flag:flag_top_red",
	"ctf_flag:flag_top_blue",
}

for _, flagname in pairs(flags) do
	local old_func = minetest.registered_nodes[flagname].on_punch
	local function on_punch(pos, node, player, ...)
		if ctf_classes.get(player).name == "medic" then
			local flag = ctf_flag.get(pos)
			local team = ctf.player(player:get_player_name()).team
			if not flag or not flag.team or not team or team ~= flag.team then
				minetest.chat_send_player(player:get_player_name(),
					"Medics can't capture the flag!")
				return
			end
		end

		return old_func(pos, node, player, ...)
	end
	local function show(_, _, player)
		ctf_classes.show_gui(player:get_player_name(), player)
	end
	minetest.override_item(flagname, {
		on_punch = on_punch,
		on_rightclick = show,
	})
end
