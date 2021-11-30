ctf_hpbar = {}
local max = {hp = 20}
local players = {}

minetest.register_entity("ctf_hpbar:entity", {
	visual = "sprite",
	visual_size = {x=1, y=1/16, z=1},
	textures = {"blank.png"},
	physical = false,
	makes_footstep_sound = false,
	backface_culling = false,
	static_save = false,
	pointable = false,
	on_punch = function() return true end,
})

-- credit:
-- https://github.com/minetest/minetest/blob/6de8d77e17017cd5cc7b065d42566b6b1cd076cc/builtin/game/statbars.lua#L30-L37
local function scaleToDefault(player, field)
	-- Scale "hp" or "breath" to supported amount
	local current = player["get_" .. field](player)
	local max_display = math.max(player:get_properties()[field .. "_max"], current)
	if max_display == 0 then
		return 0
	end
	return math.round(current * max[field] / max_display)
end

local function update_entity(player)
	local pname = player:get_player_name()
	local hp = scaleToDefault(player, "hp")

	if players[pname].hp == hp then
		return
	end
	players[pname].hp = hp

	local health_t = "blank.png"
	if hp > 0 then
		health_t = "health_" .. hp .. ".png"
	end

	players[pname].entity:set_properties({textures = {health_t}})
end

minetest.register_playerevent(function(player, eventname)
	if eventname == "health_changed" or eventname == "properties_changed" then
		if players[player:get_player_name()] ~= nil then
			update_entity(player)
		end
	end
end)

function ctf_hpbar.can_show(player)
    return true
end

minetest.register_on_joinplayer(function(player)
    if not ctf_hpbar.can_show(player) then return end

    local entity = minetest.add_entity(player:get_pos(), "ctf_hpbar:entity")
    entity:set_attach(player, "", {x=0, y=19, z=0}, {x=0, y=0, z=0})
    players[player:get_player_name()] = {entity=entity}

    update_entity(player)
end)

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	if players[pname] ~= nil then
		players[pname].entity:remove()
		players[pname] = nil
	end
end)
