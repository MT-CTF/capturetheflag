------------------
-- Private data --
------------------

-- Keep track of players who are scoping in, and their wielded item
local scoped = {}

-- Timer for scope-check globalstep
local timer = 0.2

-------------
-- Helpers --
-------------

local function show_scope(name, item_name, fov_mult)
	local player = minetest.get_player_by_name(name)
	if not player then
		return
	end

	scoped[name] = item_name
	-- e.g. if fov_mult == 8, then FOV = 1/8 * current_FOV, a.k.a 8x zoom
	player:set_fov(1 / fov_mult, true)
	player:set_hud_flags({ wielditem = false })
end

local function hide_scope(name)
	local player = minetest.get_player_by_name(name)
	if not player then
		return
	end

	scoped[name] = nil
	player:set_fov(0)
	player:set_hud_flags({ wielditem = true })
end

local function on_rclick(item, placer, pointed_thing)
	if pointed_thing.type == "object" then
		return
	end

	local name = placer:get_player_name()
	if scoped[name] then
		hide_scope(name)
	else
		-- Remove _loaded suffix added to item name by shooter
		local item_name = item:get_name():gsub("_loaded", "")
		local fov_mult = shooter.registered_weapons[item_name].fov_mult
		show_scope(name, item_name, fov_mult)
	end
end

------------------
-- Sccope-check --
------------------

-- Hide scope if currently wielded item is not the same item
-- player wielded when scoping

local time = 0
minetest.register_globalstep(function(dtime)
	time = time + dtime
	if time < timer then
		return
	end

	time = 0
	for name, original_item in pairs(scoped) do
		local player = minetest.get_player_by_name(name)
		if not player then
			scoped[name] = nil
		else
			local wielded_item = player:get_wielded_item()
			if wielded_item ~= original_item then
				hide_scope(name)
			end
		end
	end
end)

----------------------------
-- Rifle registration API --
----------------------------

sniper_rifles = {}

function sniper_rifles.register_rifle(name, def)
	assert(def.fov_mult, "Rifle def must contain FOV multiplier (fov_mult)!")

	shooter.register_weapon(name, def)

	-- Manually add extra fields to itemdef that shooter doesn't allow
	-- Also modify the _loaded variant
	local overrides = {
		on_secondary_use = on_rclick,
		wield_scale = vector.new(2, 2, 1.5)
	}
	minetest.override_item(name, overrides)
	minetest.override_item(name .. "_loaded", overrides)

end

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/rifles.lua")
