-- `ctf_anticombatlog` mod by ClobberXD, published under the MIT license
-- Heavily modified and optimised version of `anticombatlog` by Elkien3

local players = {}
local combat_timeout = 5
local entity_timeout = 10

local function pvp_engage(name)
	if not players[name] then
		players[name] = {time = combat_timeout}
	else
		players[name].time = combat_timeout
	end

	local player = minetest.get_player_by_name(name)
	if not players[name].hud then
		players[name].hud = player:hud_add({
			hud_elem_type = "image",
			position = {x = 1, y = 1},
			offset = {x = -100, y = -100},
			scale = {x = -10, y = -10},
			text = "ctf_anticombatlog_pvp.png"
		})
	end
end

local function pvp_disengage(name)
	if not players[name] then
		return
	end
	local player = minetest.get_player_by_name(name)
	if player then
		player:hud_remove(players[name].hud)
	end
	players[name] = nil
end

local function transfer_state(from, to)
	if not from or not to then
		return
	end

	to:set_properties(from:get_properties())
	to:set_pos(from:get_pos())
	to:set_yaw(from:get_yaw())
end

-- combat_timeout timer
minetest.register_globalstep(function(dtime)
	for name, info in pairs(players) do
		info.time = info.time + dtime
		if info.time > combat_timeout then
			pvp_disengage(name)
		end
	end
end)

minetest.register_on_punchplayer(function(player, hitter)
	if not player or not hitter then
		return
	end

	local hname = hitter:get_player_name()
	local pname = player:get_player_name()

	-- Return if hitter and player are on the same team
	if ctf.player(hname).team == ctf.player(pname).team then
		return
	end

	-- Return if hitter punches dead player
	if player:get_hp() == 0 then
		return
	end

	pvp_engage(pname)
	pvp_engage(hname)
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if not players[name] then
		return
	end

	-- Player combat-logged; do the needful
	local pos = player:get_pos()
	local obj = minetest.add_entity(pos, "ctf_anticombatlog:ghost")
	obj:get_luaentity()._pname = name
	players[name].ghost = obj
	if obj then
		transfer_state(player, obj)
	end
	local ghost_inv = minetest.create_detached_inventory(name .. "_ghost", {})
	local player_inv = player:get_inventory()
	ghost_inv:set_lists(player_inv:get_lists())

	-- Remove object after `entity_timeout` seconds
	minetest.after(entity_timeout, obj.remove, obj)
end)

minetest.register_on_dieplayer(function(player)
	players[player:get_player_name()] = nil
end)

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if not players[name] then
		return
	end

	local ghost = players[name].ghost
	if ghost then
		transfer_state(ghost, player)
		ghost:remove()
		players[name] = nil
	end
end)

minetest.register_entity("ctf_anticombatlog:ghost",
{
	initial_properties = {
		hp_max = 20,
		physical = true,
		collisionbox = {-0.35, -1.0, -0.35, 0.35, 0.8, 0.35},
		visual = "mesh",
		visual_size = {x = 1, y = 1},
		mesh = "character.b3d",
		textures = {"character.png"},
		is_visible = true
	},
	on_punch = function(self, puncher, _, _, _, damage)
		local hname = puncher:get_player_name()
		local pname = self._pname
		pvp_engage(pname)
		pvp_engage(hname)

		if self.object:get_hp() - damage <= 0 then
			local inv = minetest.get_inventory({
				type = "detached",
				name = pname .. "_ghost"
			})
			dropondie.drop_all(inv, self.object:get_pos())
			self.object:remove()
			players[pname] = nil

			-- Run all on_killedplayer callbacks
			for _, fn in pairs(ctf.registered_on_killedplayer) do
				fn(hname, pname .. " (combat-logged)", "sword")
			end
		end
	end
})
