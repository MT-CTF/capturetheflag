-- HudKit, by rubenwardy
-- License: Either WTFPL or CC0, you can choose.

local function hudkit()
	return {
		players = {},

		add = function(self, player, id, def)
			local name = player:get_player_name()
			local elements = self.players[name]

			if not elements then
				self.players[name] = {}
				elements = self.players[name]
			end

			elements[id] = player:hud_add(def)
		end,

		exists = function(self, player, id)
			local elements = self.players[player:get_player_name()]
			return elements and elements[id]
		end,

		change = function(self, player, id, stat, value)
			local elements = self.players[player:get_player_name()]
			if not elements or not elements[id] then
				return false
			end

			player:hud_change(elements[id], stat, value)
			return true
		end,

		remove = function(self, player, id)
			local elements = self.players[player:get_player_name()]
			if not elements or not elements[id] then
				return false
			end

			player:hud_remove(elements[id])
			elements[id] = nil
			return true
		end
	}
end

return hudkit
