-- Adds health bars above players.
-- Code by 4aiman, textures by Calinou. Licensed under CC0.

gauges = {}

local hp_bar = {
	physical = false,
	collisionbox = {x = 0, y = 0, z = 0},
	visual = "sprite",
	textures = {"20.png"}, -- The texture is changed later in the code.
	visual_size = {x = 1.5, y = 0.09375, z = 1.5}, -- Y value is (1 / 16) * 1.5.
	wielder = nil,
}

function vector.sqdist(a, b)
	local dx = a.x - b.x
	local dy = a.y - b.y
	local dz = a.z - b.z
	return dx*dx + dy*dy + dz*dz
end

function hp_bar:on_step(dtime)
	local wielder = self.wielder and minetest.get_player_by_name(self.wielder)
	if wielder == nil then
		minetest.log("warning", "[gauges] Gauge removed as null wielder! " .. dump(self.wielder))
		self.object:remove()
		return
	end

	if vector.sqdist(wielder:get_pos(), self.object:get_pos()) > 3 then
		minetest.log("warning", "[gauges] Gauge removed as not attached! " .. dump(self.wielder))
		self.object:remove()
		return
	end

	local hp = wielder:get_hp()
	local breath = wielder:get_breath()
	self.object:set_properties({
		textures = {
			"health_" .. tostring(hp) .. ".png^breath_" .. tostring(breath) .. ".png",
		},
	})
end

minetest.register_entity("gauges:hp_bar", hp_bar)

function gauges.add_HP_gauge(name)
	local player = minetest.get_player_by_name(name)
	if player then
		local pos = player:get_pos()
		local ent = minetest.add_entity(pos, "gauges:hp_bar")
		assert(ent)
		if ent ~= nil then
			ent:set_attach(player, "", {x = 0, y = 19, z = 0}, {x = 0, y = 0, z = 0})
			ent = ent:get_luaentity()
			ent.wielder = player:get_player_name()
		end
	end
end

-- If health_bars not defined or set to true
if minetest.settings:get_bool("health_bars") ~= false and
		minetest.settings:get_bool("enable_damage") then
	minetest.register_on_joinplayer(function(player)
		minetest.after(2, gauges.add_HP_gauge, player:get_player_name())
	end)
end

function gauges.check_gauges()
	for _, player in pairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local found = false
		local objects = minetest.get_objects_inside_radius(player:get_pos(), 1)
		for _, object in pairs(objects) do
			local le = object:get_luaentity()
			if le and le.wielder == pname then
				found = true
				break
			end
		end

		if not found then
			minetest.log("warning", "[gauges] Gauge not found for player " .. pname)
			gauges.add_HP_gauge(pname)
		end
	end
	minetest.after(9.3, gauges.check_gauges)
end
minetest.after(2, gauges.check_gauges)
