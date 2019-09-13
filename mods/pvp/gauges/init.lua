-- gauges: Adds health/breath bars above players
--
-- Copyright © 2014-2019 4aiman, Hugo Locurcio and contributors - MIT License
-- See `LICENSE.md` included in the source distribution for details.

local hp_bar = {
	physical = false,
	collisionbox = {x = 0, y = 0, z = 0},
	visual = "sprite",
	textures = {"health_20.png"}, -- The texture is changed later in the code
	visual_size = {x = 1.5, y = 0.09375, z = 1.5}, -- Y value is (1 / 16) * 1.5
}

function hp_bar:set_hp(hp)
	self.object:set_properties({
		textures = {
			"health_" .. tostring(hp) .. ".png",
		},
	})
end
function hp_bar:on_detach()
  self.object:remove()
end

minetest.register_entity("gauges:hp_bar", hp_bar)

local gauge_list = {}

local function add_hp_gauge(player)
  local pos = player:get_pos()
  local ent = minetest.add_entity(pos, "gauges:hp_bar")

  if ent then
    ent:set_attach(player, "", {x = 0, y = 19, z = 0}, {x = 0, y = 0, z = 0})
    ent = ent:get_luaentity()
    gauge_list[player:get_player_name()] = ent
    ent:set_hp(player:get_hp())
  end
end

local function cleanup()
  -- Check for any detatched hp_bar on the map
  for _, entity in pairs(minetest.luaentities) do
    if entity.name == "gauges:hp_bar" and entity.object:get_attach() == nil then
      entity.object:remove()
    end
  end
end


if
	minetest.settings:get_bool("enable_damage") and
	minetest.settings:get_bool("health_bars")
then
	minetest.register_on_joinplayer(function(player)
    -- If the server was shut down brutally (for example using Ctrl-c)
    -- we didn't have the time to remove the detatched bars.
    -- So every time a player joins, we check if there is
    -- a detatched bar somewhere and we remove it
    minetest.after(2, cleanup)
    -- The player takes some time to spawn and get a correct position.
    -- We need to wait, or the gauge will be stuck under the player
    minetest.after(3, add_hp_gauge, player)
  end)
  minetest.register_on_player_hpchange(function (player, hpchange)
    local name = player:get_player_name()
    if gauge_list[name] then
      gauge_list[name]:set_hp(player:get_hp() + hpchange)
    end
  end, false)
end
