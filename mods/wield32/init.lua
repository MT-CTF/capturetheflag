WIELD3D_INIT_DELAY = 1
WIELD3D_RETRY_TIME = 10
WIELD3D_UPDATE_TIME = 1

local modpath = minetest.get_modpath(minetest.get_current_modname())
local input = io.open(modpath.."/wield3d.conf", "r")
if input then
	dofile(modpath.."/wield3d.conf")
	input:close()
	input = nil
end
dofile(modpath.."/location.lua")

local location = {
	"Arm_Right",           -- default bone
	{x=0.2, y=6.5, z=3},   -- default position
	{x=-100, y=225, z=90}, -- default rotation
}
local player_wielding = {}
local timer = 0

local function add_wield_entity(player)
	local name = player:get_player_name()
	local pos = player:getpos()
	local inv = player:get_inventory()
	if name and pos and inv then
		local offset = {x=pos.x, y=pos.y + 0.5, z=pos.z}
		local object = minetest.add_entity(offset, "wield3d:wield_entity")
		if object then
			object:set_properties({collisionbox={0,0,0, 0,0,0}})
			object:set_attach(player, location[1], location[2], location[3])
			local entity = object:get_luaentity()
			if entity then
				entity.player = player
				player_wielding[name] = 1
			else
				object:remove()
			end
		end
	end
end

minetest.register_item("wield3d:hand", {
	type = "none",
	wield_image = "wield3d_trans.png",
})

minetest.register_entity("wield3d:wield_entity", {
	physical = false,
	collisionbox = {-0.125,-0.125,-0.125, 0.125,0.125,0.125},
	visual = "wielditem",
	visual_size = {x=0.25, y=0.25},
	textures = {"wield3d:hand"},
	player = nil,
	item = nil,
	timer = 0,
	location = {location[1], location[2], location[3]},
	on_step = function(self, dtime)
		self.timer = self.timer + dtime
		if self.timer < WIELD3D_UPDATE_TIME then
			return
		end
		self.timer = 0
		local player = self.player
		if player then
			local name = player:get_player_name()
			local p1 = player:getpos()
			local p2 = self.object:getpos()
			if p1 and p2 then
				if vector.equals(p1, p2) then
					local stack = player:get_wielded_item()
					local item = stack:get_name() or ""
					if item == self.item then
						return
					end
					if minetest.get_modpath("wieldview") then
						local def = minetest.registered_items[item] or {}
						if def.inventory_image ~= "" then
							item = ""
						end
					end
					self.item = item
					if item == "" then
						item = "wield3d:hand"
					end
					local loc = wield3d_location[item] or location
					if loc[1] ~= self.location[1]
					or vector.equals(loc[2], self.location[2]) == false
					or vector.equals(loc[3], self.location[3]) == false then
						self.object:set_detach()
						self.object:set_attach(player, loc[1], loc[2], loc[3])
						self.location = {loc[1], loc[2], loc[3]}
					end
					self.object:set_properties({textures={item}})
					return
				end
			end
			player_wielding[name] = 0
		end
		self.object:remove()
	end,
})

minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer > WIELD3D_RETRY_TIME then
		for name, state in pairs(player_wielding) do
			if state == 0 then
				local player = minetest.get_player_by_name(name)
				if player then
					add_wield_entity(player)
				else
					player_wielding[name] = nil
				end
			end
		end
		timer = 0
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if name then
		player_wielding[name] = nil
	end
end)

minetest.register_on_joinplayer(function(player)
	player_wielding[player:get_player_name()] = 0
	minetest.after(WIELD3D_INIT_DELAY, add_wield_entity, player)
end)

