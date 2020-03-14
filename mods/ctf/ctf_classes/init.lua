ctf_classes = {
	__classes = {},
	__classes_ordered = {},

	default_class = "knight",
}

dofile(minetest.get_modpath("ctf_classes") .. "/api.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/gui.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/regen.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/ranged.lua")
dofile(minetest.get_modpath("ctf_classes") .. "/items.lua")


ctf_classes.register("knight", {
	description = "Knight",
	pros = { "+50% Health Points" },
	cons = { "-10% speed" },
	color = "#ccc",
	properties = {
		max_hp = 30,
		speed = 0.90,

		items = {
			"default:sword_steel",
		},

		allowed_guns = {
			"shooter:pistol",
			"shooter:smg",
			"shooter:shotgun",
		},
	},
})

ctf_classes.register("shooter", {
	description = "Sharp Shooter",
	pros = { "+50% range", "+20% faster shooting" },
	cons = {},
	color = "#c60",
	properties = {
		items = {
			"shooter:rifle",
			"shooter:grapple_gun_loaded",
		},

		allowed_guns = {
			"shooter:pistol",
			"shooter:rifle",
			"shooter:smg",
			"shooter:shotgun",
		},

		shooter_multipliers = {
			range = 1.5,
			full_punch_interval = 0.8,
		},
	},
})

ctf_classes.register("medic", {
	description = "Medic",
	pros = { "x2 regen for nearby friendlies" },
	cons = {},
	color = "#0af",
	properties = {
		items = {
			"ctf_bandages:bandage 20",
		},

		allowed_guns = {
			"shooter:pistol",
			"shooter:smg",
			"shooter:shotgun",
		},
	},
})

ctf_classes.register("rocketeer", {
	description = "Rocketeer",
	pros = { "Can craft rockets" },
	cons = {},
	color = "#fa0",
	properties = {
		items = {
			"shooter:rocket_gun_loaded",
			"shooter:rocket 4",
		},

		allowed_guns = {
			"shooter:pistol",
			"shooter:smg",
			"shooter:shotgun",
		},
	},
})



minetest.register_on_joinplayer(function(player)
	ctf_classes.update(player)

	if minetest.check_player_privs(player, { interact = true }) then
		ctf_classes.show_gui(player:get_player_name())
	end
end)

ctf_flag.register_on_pick_up(function(name)
	ctf_classes.update(minetest.get_player_by_name(name))
end)

ctf_flag.register_on_drop(function(name)
	ctf_classes.update(minetest.get_player_by_name(name))
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

local flags = {
	"ctf_flag:flag",
	"ctf_flag:flag_top_red",
	"ctf_flag:flag_top_blue",
}

for _, flagname in pairs(flags) do
	local old_func = minetest.registered_nodes[flagname].on_punch
	local function on_punch(pos, node, player, ...)
		local fpos = pos
		if node.name:sub(1, 18) == "ctf_flag:flag_top_" then
			fpos = vector.new(pos)
			fpos.y = fpos.y - 1
		end

		local class = ctf_classes.get(player)
		if not class.properties.can_capture then
			local pname = player:get_player_name()
			local flag = ctf_flag.get(fpos)
			local team = ctf.player(pname).team
			if flag and flag.team and team and team ~= flag.team then
				minetest.chat_send_player(pname,
					"You need to change classes to capture the flag!")
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

ctf_classes.register_on_changed(function(player, old, new)
	if not old then
		return
	end

	local pname = player:get_player_name()
	ctf.chat_send_team(ctf.player(pname).team,
			minetest.colorize("#ABCDEF", pname .. " is now a " .. new.description))
end)
