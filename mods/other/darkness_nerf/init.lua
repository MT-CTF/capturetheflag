minetest.register_on_joinplayer(function(player)
	player:set_properties({glow = 3})
end)

local MIN_GLOW = 8

minetest.register_on_mods_loaded(function()
	local itemdef = minetest.registered_entities["__builtin:item"]
	local old_set_item = itemdef.set_item

	itemdef.set_item = function(self, itemstring)
		old_set_item(self, itemstring)
		local iname = itemstring or self.itemstring
		iname = ItemStack(iname):get_name()

		if not minetest.registered_items[iname] or (minetest.registered_items[iname].light_source or 0) < MIN_GLOW then
			self.object:set_properties({glow = MIN_GLOW})
		else
			self.object:set_properties({glow = minetest.registered_items[iname].light_source})
		end
	end

	minetest.register_entity(":__builtin:item", itemdef)
end)
