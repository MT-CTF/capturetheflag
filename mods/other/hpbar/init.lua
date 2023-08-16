hpbar = {}
local max = {hp = 20}
local players = {}

local HPBAR_SCALE = 0.023
minetest.register_entity("hpbar:entity", {
	visual = "sprite",
	visual_size = {x = 58 * HPBAR_SCALE, y = 16 * HPBAR_SCALE}, -- texture is 58 x 16
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

-- Returns true if player has entity, will give them one if they need it but don't have it for some reason
local function has_entity(player)
	local pname = player:get_player_name()

	if not hpbar.can_show(player) then
		if players[pname] then
			players[pname].entity:remove()
			players[pname] = nil

			return false
		end

		return false
	end

	if players[pname] then
		if players[pname].entity and players[pname].entity:get_luaentity() then
			return true
		else
			players[pname].entity:remove()
		end
	end

	local entity = minetest.add_entity(player:get_pos(), "hpbar:entity")

	entity:set_attach(player, "", {x=0, y=18.8, z=0}, {x=0, y=0, z=0})

	if not players[pname] then
		players[pname] = {entity=entity}
	else
		players[pname].entity = entity
	end

	return true
end

local function update_entity(player, new_icon_texture)
	local pname = player:get_player_name()
	local hp = scaleToDefault(player, "hp")


	if not players[pname] or not players[pname].entity or not players[pname].entity:get_luaentity() then
		if not has_entity(player) then
			return
		end
	end

	players[pname].hp = hp

	local health_t = "blank.png"
	local prop = players[pname].entity:get_properties()

	if hp > 0 then
		health_t = "hpbar_hp_" .. hp .. ".png"
	end

	if new_icon_texture and players[pname].icon ~= new_icon_texture then
		players[pname].icon = new_icon_texture
	else
		new_icon_texture = false
	end

	if prop.textures[1] ~= health_t or new_icon_texture then
		if players[pname].icon and players[pname].icon ~= "" then
			players[pname].entity:set_properties({textures = {
				"[combine:58x16:-2,0="..health_t..":0,3="..players[pname].icon
			}})
		else
			players[pname].entity:set_properties({textures = {
				"[combine:58x16:-8,0="..health_t
			}})
		end
	end
end

function hpbar.set_icon(player, texture)
	update_entity(PlayerObj(player), texture)
end

minetest.register_playerevent(function(player, eventname)
	if eventname == "health_changed" or eventname == "properties_changed" then
		if players[player:get_player_name()] ~= nil then
			update_entity(player)
		end
	end
end)

function hpbar.can_show(player)
	return true
end

minetest.register_on_joinplayer(function(player)
	if has_entity(player) then
		update_entity(player)
	end
end)

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	if players[pname] ~= nil then
		players[pname].entity:remove()
		players[pname] = nil
	end
end)
