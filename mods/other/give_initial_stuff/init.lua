give_initial_stuff = {}

local tools = {"default:sword_", "default:pick_", "default:axe_", "default:shovel_"}
local tool_materials = {"stone", "steel", "bronze", "mese", "diamond"}

-- Add item to inv. Split item if count > stack_max using recursion
function give_initial_stuff.give_item(inv, item)
	-- Remove any lower tier tools of the same type as the item
	for _, tool in pairs(tools) do
		if item:get_name():find(tool) then -- Find what tool the new item is
			-- Get the 'tier' of the new item
			local newtier = table.indexof(tool_materials, item:get_name():sub(tool:len() + 1))

			for tier, mat in ipairs(tool_materials) do
				if tier < newtier then
					inv:remove_item("main", tool..mat) -- Will do nothing if tool doesn't exist
				elseif inv:contains_item("main", tool..mat) then
					return -- A higher tier tool is already in inventory
				end
			end
		end
	end

	-- Don't duplicate stacks
	if inv:contains_item("main", item:get_name()) then
		local safeguard = 1
		-- Do a fast refill of stack if needed
		while not inv:contains_item("main", item:get_name().." "..item:get_stack_max()-5) do
			safeguard = safeguard + 1
			inv:add_item("main", item:get_name().." 5")

			if safeguard >= 500 then
				minetest.log("error", "[give_initial_stuff] Something went wrong when filling stack "..dump(item:get_name()))
				break
			end
		end

		return
	end

	inv:add_item("main", item:take_item(item:get_stack_max()))

	-- If item isn't empty, add the leftovers again
	if not item:is_empty() then
		give_initial_stuff.give_item(inv, item)
	end
end

setmetatable(give_initial_stuff, {
	__call = function(self, player, mode)
		minetest.log("action", "Giving initial stuff to player "
				.. player:get_player_name())
		local inv = player:get_inventory()

		if mode ~= "replace_tools" then
			inv:set_list("main",  {})
			inv:set_list("craft", {})

			inv:set_size("craft", 1)
			inv:set_size("craftresult", 0)
			inv:set_size("hand", 0)
		end

		local items = give_initial_stuff.get_stuff(player)

		for _, item in pairs(items) do
			if mode == "replace_tools" then
				for _, tool in pairs(tools) do
					if item:find(tool) then
						give_initial_stuff.give_item(inv, ItemStack(item))
					end
				end
			else
				give_initial_stuff.give_item(inv, ItemStack(item))
			end
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
