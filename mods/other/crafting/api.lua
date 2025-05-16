crafting = {
	recipes = {},
	recipes_by_id = {},
}

function crafting.register_recipe(def)
	assert(def.output, "Output needed in recipe definition")
	assert(def.items,  "Items needed in recipe definition")

	def.id = #crafting.recipes
	crafting.recipes_by_id[def.id] = def
	table.insert(crafting.recipes, def)

	return def.id
end

local players_recipes = {}
function crafting.get_unlocked(name)
	if not players_recipes[name] then
		players_recipes[name] = {}
	end

	return players_recipes[name]
end

core.register_on_leaveplayer(function(player)
	players_recipes[player:get_player_name()] = nil
end)

function crafting.lock_all(name)
	players_recipes[name] = nil
end

function crafting.unlock(name, output)
	local unlocked = crafting.get_unlocked(name)

	if type(output) == "table" then
		for i=1, #output do
			unlocked[output[i]] = true
		end
	else
		unlocked[output] = true
	end
end

function crafting.can_craft(name, recipe)
	local unlocked = crafting.get_unlocked(name)
	return recipe.always_known or unlocked[recipe.output]
end

function crafting.get_recipe(id)
	return crafting.recipes_by_id[id]
end

function crafting.get_all_recipes(player_items, unlocked)
	local results = {}

	for _, recipe in ipairs(crafting.recipes) do
		local craftable = true

		if recipe.always_known or unlocked[recipe.output] then
			-- Check all ingredients are available
			local items = {}
			for _, item in ipairs(recipe.items) do
				item = ItemStack(item)
				local name = item:get_name()
				local needed_count = item:get_count()

				local available_count = player_items[name] or 0
				if available_count < needed_count then
					craftable = false
				end

				table.insert(items, {
					name = name,
					have = available_count,
					need = needed_count,
				})
			end

			table.insert(results, {
				recipe    = recipe,
				items     = items,
				craftable = craftable,
			})
		end
	end

	return results
end

local function fetch_items_from_inv(inv, listname)
	local items = {}

	for _, stack in ipairs(inv:get_list(listname)) do
		if not stack:is_empty() then
			local itemname = stack:get_name()
			items[itemname] = (items[itemname] or 0) + stack:get_count()

			local def = core.registered_items[itemname]
			if def and def.groups then
				for groupname, _ in pairs(def.groups) do
					local group = "group:" .. groupname
					items[group] = (items[group] or 0) + stack:get_count()
				end
			end
		end
	end

	return items
end

function crafting.get_all_for_player(player)
	local unlocked = crafting.get_unlocked(player:get_player_name())
	local items = fetch_items_from_inv(player:get_inventory(), "main")
	return crafting.get_all_recipes(items, unlocked)
end

local function give_all_to_player(inv, list)
	for _, item in ipairs(list) do
		inv:add_item("main", item)
	end
end

local function find_required_items(inv, listname, recipe)
	local items = {}
	for _, item in ipairs(recipe.items) do
		item = ItemStack(item)

		local itemname = item:get_name()
		if item:get_name():sub(1, 6) == "group:" then
			local groupname = itemname:sub(7, #itemname)
			local required = item:get_count()

			-- Find stacks in group
			for _, stack in ipairs(inv:get_list(listname)) do
				-- Is it in group?
				local def = core.registered_items[stack:get_name()]
				if def and def.groups and def.groups[groupname] then
					if stack:get_count() > required then
						stack:set_count(required)
					end
					items[#items + 1] = stack

					required = required - stack:get_count()

					if required == 0 then
						break
					end
				end
			end

			if required > 0 then
				return nil
			end
		else
			if inv:contains_item(listname, item) then
				items[#items + 1] = item
			else
				return nil
			end
		end
	end

	return items
end

function crafting.perform_craft(player, listname, outlistname, recipe)
	local inv = player:get_inventory()

	local items = find_required_items(inv, listname, recipe)
	if not items then
		return false
	end

	-- Take items
	local taken = {}
	for _, item in ipairs(items) do
		item = ItemStack(item)

		local took = inv:remove_item(listname, item)
		taken[#taken + 1] = took
		if took:get_count() ~= item:get_count() then
			core.log("error", "Unexpected lack of items in inventory")
			give_all_to_player(inv, taken)
			return false
		end
	end

	-- Add output
	if inv:room_for_item(outlistname, recipe.output) then
		inv:add_item(outlistname, recipe.output)
	else
		local pos = player:get_pos()
		core.chat_send_player(player:get_player_name(), "No room in inventory!")
		core.add_item(pos, recipe.output)
	end
	return true
end

local function to_hex(str)
	return (str:gsub('.', function (c)
		return string.format('%02X', string.byte(c))
	end))
end

function crafting.calc_inventory_list_hash(inv, listname)
	local str = ""
	for _, stack in pairs(inv:get_list(listname)) do
		str = str .. stack:get_name() .. stack:get_count()
	end
	return core.sha1(to_hex(str))
end
