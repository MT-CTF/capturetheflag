function ctf_classes.register(cname, def)
	assert(not ctf_classes.__classes[cname])
	def.name = cname
	ctf_classes.__classes[cname] = def
	table.insert(ctf_classes.__classes_ordered, def)

	def.pros   = def.pros or {}
	def.cons   = def.cons or {}

	def.properties = def.properties or {}
	if def.properties.can_capture == nil then
		def.properties.can_capture = true
	end

	def.properties.initial_stuff = def.properties.initial_stuff or {}

	if not def.properties.item_blacklist then
		def.properties.item_blacklist = {}
		for i, item in ipairs(def.properties.initial_stuff) do
			local iname = ItemStack(item):get_name()

			-- Only add to item blacklist if not in the whitelist
			if table.indexof(def.properties.item_whitelist or {}, iname) == -1 then
				def.properties.item_blacklist[i] = iname
			end
		end
	end

	if def.properties.additional_item_blacklist then
		for i=1, #def.properties.additional_item_blacklist do
			table.insert(def.properties.item_blacklist,
				def.properties.additional_item_blacklist[i])
		end
	end

	-- Validate items
	for i=1, #def.properties.initial_stuff do
		local item_name = ItemStack(def.properties.initial_stuff[i]):get_name()
		assert(minetest.registered_items[item_name], "Item " .. item_name .. " not found")
	end
	for i=1, #def.properties.item_blacklist do
		local item_name = def.properties.item_blacklist[i]
		assert(minetest.registered_items[item_name], "Item " .. item_name .. " not found")
	end

	def.properties.speed  = def.properties.speed or 1
	def.properties.max_hp = def.properties.max_hp or 20
end

local registered_on_changed = {}
function ctf_classes.register_on_changed(func)
	table.insert(registered_on_changed, func)
end

function ctf_classes.set_skin(player, color, class)
	player:set_properties({
		textures = {"ctf_classes_skin_" .. class.name .. "_" .. (color or "blue") .. ".png"}
	})
end

function ctf_classes.get(player)
	if type(player) == "string" then
		player = minetest.get_player_by_name(player)
	end

	-- Return class from player meta if valid, or default class
	local cname = player:get_meta():get("ctf_classes:class")
	if not ctf_classes.__classes[cname] then
		cname = ctf_classes.default_class
	end
	return ctf_classes.__classes[cname]
end

function ctf_classes.set(player, new_name)
	assert(type(new_name) == "string")
	local new = ctf_classes.__classes[new_name]
	assert(new)

	local meta = player:get_meta()
	local old_name = meta:get("ctf_classes:class")

	meta:set_string("ctf_classes:class", new_name)
	ctf_classes.update(player)

	ctf_classes.set_cooldown(player:get_player_name())

	if old_name == nil or old_name ~= new_name then
		local old = old_name and ctf_classes.__classes[old_name]
		for i=1, #registered_on_changed do
			registered_on_changed[i](player, old, new)
		end
	end
end

local function set_max_hp(player, max_hp)
	local cur_hp = player:get_hp()
	local old_max = player:get_properties().hp_max
	local new_hp = cur_hp + max_hp - old_max
	player:set_properties({
		hp_max = max_hp
	})

	if new_hp > max_hp then
		minetest.log("error", string.format("New hp %d is larger than new max %d, old max is %d", new_hp, max_hp, old_max))
		new_hp = max_hp
	end

	if cur_hp > max_hp then
		player:set_hp(max_hp)
	elseif new_hp > cur_hp then
		player:set_hp(new_hp)
	end
end

function ctf_classes.update(player)
	local name = player:get_player_name()

	local class = ctf_classes.get(player)
	local color = ctf_colors.get_color(ctf.player(name)).text

	set_max_hp(player, class.properties.max_hp)
	ctf_classes.set_skin(player, color, class)

	physics.set(player:get_player_name(), "ctf_classes:physics", {
		speed = class.properties.speed,
		jump = class.properties.jump,
		gravity = class.properties.gravity,
	})

	crafting.lock_all(player:get_player_name())
	for i=1, #(class.properties.crafting or {}) do
		crafting.unlock(player:get_player_name(), class.properties.crafting[i])
	end
end

local function sqdist(a, b)
	local x = a.x - b.x
	local y = a.y - b.y
	local z = a.z - b.z
	return x*x + y*y + z*z
end

function ctf_classes.get_flag_pos(player)
	local tplayer = ctf.player(player:get_player_name())
	if not tplayer or not tplayer.team then
		return nil
	end

	local team = ctf.team(tplayer.team)
	if team and team.flags[1] then
		return vector.new(team.flags[1])
	end
	return nil
end

function ctf_classes.can_change(player)
	if minetest.check_player_privs(player, "ctf_admin") then
		return true
	end

	if ctf_classes.get_cooldown(player:get_player_name()) then
		return false, "You need to wait to change classes again!"
	end

	local flag_pos = ctf_classes.get_flag_pos(player)
	if flag_pos then
		return sqdist(player:get_pos(), flag_pos) < 25,
			"Move closer to the flag to change classes!"
	end

	return false, "Flag does not exist!"
end

-- Cooldown time to prevent consumables abuse by changing to a class and back
local COOLDOWN_TIME = 30
local cooldown = {}

function ctf_classes.get_cooldown(name)
	return cooldown[name]
end

function ctf_classes.set_cooldown(name)
	cooldown[name] = true
	minetest.after(COOLDOWN_TIME, function()
		cooldown[name] = nil
	end)
end

minetest.register_on_dieplayer(function(player)
	cooldown[player:get_player_name()] = nil
end)
