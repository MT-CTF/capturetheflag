give_initial_stuff = {}

-- Add item to inv. Split item if count > stack_max using recursion
function give_initial_stuff.give_item(inv, item)
	inv:add_item("main", item:take_item(item:get_stack_max()))

	-- If item isn't empty, add the leftovers again
	if not item:is_empty() then
		give_initial_stuff.give_item(inv, item)
	end
end

setmetatable(give_initial_stuff, {
	__call = function(self, player)
		minetest.log("action", "Giving initial stuff to player "
				.. player:get_player_name())
		local inv = player:get_inventory()
		inv:set_list("main",  {})
		inv:set_list("craft", {})

		inv:set_size("craft", 1)
		inv:set_size("craftresult", 0)
		inv:set_size("hand", 0)

		local items = give_initial_stuff.get_stuff(player)

		for _, item in pairs(items) do
			give_initial_stuff.give_item(inv, ItemStack(item))
		end
	end
})

local registered_stuff_providers = {}
function give_initial_stuff.register_stuff_provider(func, priority)
	table.insert(registered_stuff_providers,
		priority or (#registered_stuff_providers + 1),
		func)
end

function give_initial_stuff.get_stuff(player)
	local seen_stuff = {}

	local stuff = {}
	for i=1, #registered_stuff_providers do
		local new_stuff = registered_stuff_providers[i](player)
		assert(new_stuff)

		for j=1, #new_stuff do
			local name = ItemStack(new_stuff[j]):get_name()
			if not seen_stuff[name] then
				seen_stuff[name] = true
				stuff[#stuff + 1] = new_stuff[j]
			end
		end
	end
	return stuff
end

minetest.register_on_joinplayer(function(player)
	player:set_hp(player:get_properties().hp_max)
	give_initial_stuff(player)
end)
minetest.register_on_respawnplayer(give_initial_stuff)
