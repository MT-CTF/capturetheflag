------------------
-- Private data --
------------------

-- Locally cache rifle defs for fast and easy access
local rifles = {}

-- Keep track of players who are scoping in, and their wielded item
local scoped = {}

-- Timer for scope-check globalstep
local timer = 0.2

-- List of IDs for players scoped, for use in hide_scope(). NOTE: for HUD overlay
local scoped_hud_id = {}

-- Scale constant, for crosshair. This is to ensure the crosshair will be centered.
local scale_const = 6

local default_physics_overrides = {
	speed = 0.1,
	jump = 0
}

-------------
-- Helpers --
-------------

local function show_scope(name, item_name, fov_mult)
	local player = minetest.get_player_by_name(name)
	if not player then
		return
	end

	scoped[name] = item_name
	scoped_hud_id[name] = player:hud_add({
		hud_elem_type = "image",
		position = {x = 0.5, y = 0.5},
		offset = {x = (-65*scale_const)/2, y = (-65*scale_const)/2},
		text = "rifle_crosshair.png",
		scale = {x = scale_const, y = scale_const},
		alignment = {x = 1, y = 1},
	})
	-- e.g. if fov_mult == 8, then FOV = 1/8 * current_FOV, a.k.a 8x zoom
	player:set_fov(1 / fov_mult, true)
	physics.set(name, "sniper_rifles:scoping", rifles[item_name].physics_overrides)
	player:hud_set_flags({ wielditem = false })

end

local function hide_scope(name)
	local player = minetest.get_player_by_name(name)
	if not player then
		return
	end

	scoped[name] = nil
	player:hud_remove(scoped_hud_id[name])
	scoped_hud_id[name] = nil
	player:set_fov(0)
	physics.remove(name, "sniper_rifles:scoping")
	player:hud_set_flags({ wielditem = true })

end

-- Be absolutely certain crosshair HUD gets removed on death
minetest.register_on_dieplayer(function(player)
	if scoped_hud_id[player:get_player_name()] then
		hide_scope(player:get_player_name())
	end
end)

local function on_use(stack, user, pointed)
	if scoped[user:get_player_name()] then
		-- shooter checks for the return value of def.on_use, and executes
		-- the rest of the code only if this function returns non-nil
		return stack
	end
end

local function on_rclick(item, placer, pointed_thing)
	local name = placer:get_player_name()

	-- Prioritize on "un-scoping", if player is using the scope
	if not scoped[name] and pointed_thing.type == "node" then
		return minetest.item_place(item, placer, pointed_thing)
	end

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
-- Scope-check --
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
			local wielded_item = player:get_wielded_item():get_name():gsub("_loaded", "")
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
	assert(def.fov_mult, "Rifle definition must contain FOV multiplier (fov_mult)!")

	-- Override on_use to allow firing weapon only when using the scope
	def.on_use = on_use

	shooter.register_weapon(name, def)

	-- Manually add extra fields to itemdef that shooter doesn't allow
	-- Also modify the _loaded variant
	local overrides = {
		on_place = on_rclick,
		on_secondary_use = on_rclick,
		wield_scale = vector.new(2, 2, 1.5)
	}
	minetest.override_item(name, overrides)
	minetest.override_item(name .. "_loaded", overrides)

	def.physics_overrides = def.physics_overrides or default_physics_overrides

	rifles[name] = table.copy(def)
end

local old_is_protected = minetest.is_protected
local r = ctf.setting("flag.nobuild_radius") + 5
local rs = r * r
function minetest.is_protected(pos, name, info, ...)
	if antisabotage.is_sabotage(pos, minetest.get_node(pos), minetest.get_player_by_name(name)) then
		minetest.chat_send_player(name,
			"You can't shoot blocks under your teammates!")
		return true
	end

	if r <= 0 or rs == 0 or not info or not info.is_gun then
		return old_is_protected(pos, name, info, ...)
	end

	local flag, distSQ = ctf_flag.get_nearest(pos)
	if flag and pos.y >= flag.y - 1 and distSQ < rs then
		minetest.chat_send_player(name,
			"You can't shoot blocks within "..r.." nodes of a flag!")
		return true
	else
		return old_is_protected(pos, name, info, ...)
	end
end

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/rifles.lua")
