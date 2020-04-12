------------------
-- Private data --
------------------

-- Keep track of players who are scoping in
local scoped = {}

-------------
-- Helpers --
-------------

local function show_scope(name, fov_mult)
	minetest.get_player_by_name(name):set_fov(1 / fov_mult, true)
	-- e.g. let default fov = 100, if fov_mult == 8, then final FOV = 1/8 * 100 = 12.5
end

local function hide_scope(name)
	minetest.get_player_by_name(name):set_fov(0)
end

local function on_rclick(item, placer, pointed_thing)
	if pointed_thing.type == "object" then
		return
	end

	local name = placer:get_player_name()
	if scoped[name] then
		hide_scope(name)
		scoped[name] = nil
	else
		-- Remove _loaded suffix added to item name by shooter
		local item_name = item:get_name():gsub("_loaded", "")
		local fov_mult = shooter.registered_weapons[item_name].fov_mult
		show_scope(name, fov_mult)
		scoped[name] = fov_mult
	end
end

----------------------------
-- Rifle registration API --
----------------------------

sniper_rifles = {}

function sniper_rifles.register_rifle(name, def)
	assert(def.fov_mult, "Rifle def must contain FOV multiplier (fov_mult)!")

	shooter.register_weapon(name, def)

	-- Manually add extra fields to itemdef that shooter doesn't allow
	minetest.override_item(name, {
		on_secondary_use = on_rclick,
		wield_scale = vector.new(2, 2, 1.5)
	})
end

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/rifles.lua")
