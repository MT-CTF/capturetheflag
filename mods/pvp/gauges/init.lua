-- Adds health bars above players.
-- Code by 4aiman, textures by Calinou. Licensed under CC0.

gauges = {}
gauges.entities = {}

local hp_bar = {
	physical = false,
	collisionbox = {x = 0, y = 0, z = 0},
	visual = "sprite",
	textures = {"health_20.png"},
	visual_size = {x = 1.5, y = 0.09375, z = 1.5}, -- Y value is (1 / 16) * 1.5.
	wielder = nil,
	set_hp = function(self, hp)
		local wielder = self.wielder and minetest.get_player_by_name(self.wielder)
		if not wielder then
			minetest.log("warning", "[gauges] Gauge removed as null wielder! " .. self.wielder)
			self.object:remove()
			gauges.entities[self.wielder] = nil
			return
		end

		self.object:set_properties({ textures = { "health_" .. tostring(hp) .. ".png" } })
	end
}

minetest.register_entity("gauges:hp_bar", hp_bar)

function gauges.add_HP_gauge(name)
	local player = minetest.get_player_by_name(name)
	if not player then
		return
	end

	local obj = minetest.add_entity(player:get_pos(), "gauges:hp_bar")
	if not obj then
		return
	end

	obj:set_attach(player, "", {x = 0, y = 19, z = 0}, {x = 0, y = 0, z = 0})
	local ent = obj:get_luaentity()
	ent.wielder = name
	gauges.entities[name] = ent
end

function gauges.check_gauges()
	for name, ent in pairs(gauges.entities) do
		local obj = ent.object
		if not obj:get_attach() then
			-- If gauge entity isn't attached, try re-attaching or remove entity
			local player = minetest.get_player_by_name(ent.wielder)
			if player then
				print("Detached gauge! Re-attaching to " .. ent.wielder)
				obj:set_detach()
				obj:set_attach(player, "", {x = 0, y = 19, z = 0}, {x = 0, y = 0, z = 0})
			else
				print("Detached gauge! Removing... (" .. ent.wielder .. ")")
				obj:remove()
				gauges.entities[name] = nil
			end
		end
	end
	minetest.after(5.1, gauges.check_gauges)
end
minetest.after(1.2, gauges.check_gauges)

-- If health_bars not defined or set to true
if minetest.settings:get_bool("health_bars") ~= false and
		minetest.settings:get_bool("enable_damage") then
	minetest.register_on_joinplayer(function(player)
		minetest.after(1, gauges.add_HP_gauge, player:get_player_name())
	end)

	minetest.register_on_leaveplayer(function(player)
		local name = player:get_player_name()
		local ent = gauges.entities[name]
		if ent then
			ent.object:remove()
			gauges.entities[name] = nil
		end
	end)
end

minetest.register_on_player_hpchange(function(player, hp_change)
	local ent = gauges.entities[player:get_player_name()]
	if ent then
		ent:set_hp(player:get_hp() + hp_change)
	end
end, false)

minetest.register_chatcommand("ent", {
	func = function(name)
		minetest.chat_send_player(name, dump(gauges.entities))
	end
})
