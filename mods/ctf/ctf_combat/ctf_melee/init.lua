ctf_melee = {
	registered_swords = {},
}

local sword_mats = {
	stone = {
		description = minetest.registered_tools["default:sword_stone"].description,
		inventory_image = minetest.registered_tools["default:sword_stone"].inventory_image,
		damage_groups = {fleshy = 4},
		full_punch_interval = 1.0
	},
	steel = {
		description = minetest.registered_tools["default:sword_steel"].description,
		inventory_image = minetest.registered_tools["default:sword_steel"].inventory_image,
		damage_groups = {fleshy = 6},
		full_punch_interval = 0.8,
	},
	mese = {
		description = minetest.registered_tools["default:sword_mese"].description,
		inventory_image = minetest.registered_tools["default:sword_mese"].inventory_image,
		damage_groups = {fleshy = 7},
		full_punch_interval = 0.7,
	},
	diamond = {
		description = minetest.registered_tools["default:sword_diamond"].description,
		inventory_image = minetest.registered_tools["default:sword_diamond"].inventory_image,
		damage_groups = {fleshy = 8},
		full_punch_interval = 0.6,
	}
}

local attack_cooldown = ctf_core.init_cooldowns()

function ctf_melee.simple_register_sword(name, def)
	local base_def = {
		description = def.description,
		inventory_image = def.inventory_image,
		inventory_overlay = def.inventory_overlay,
		wield_image = def.wield_image,
		tool_capabilities = {
			full_punch_interval = def.full_punch_interval,
			max_drop_level=1,
			groupcaps={
				snappy={times={[1]=2.5, [2]=1.20, [3]=0.35}, uses=0, maxlevel=3},
			},
			damage_groups = def.damage_groups,
			punch_attack_uses = 0,
		},
		sound = {breaks = "default_tool_breaks"},
		groups = def.groups or {},
	}

	base_def.groups.sword = 1

	if def.rightclick_func then
		base_def.on_place = function(itemstack, user, pointed, ...)
			local pointed_def = false
			local node

			if pointed and pointed.under then
				node = minetest.get_node(pointed.under)
				pointed_def = minetest.registered_nodes[node.name]
			end

			if pointed_def and pointed_def.on_rightclick then
				return minetest.item_place(itemstack, user, pointed)
			else
				return def.rightclick_func(itemstack, user, pointed, ...)
			end
		end

		base_def.on_secondary_use = def.rightclick_func
	end

	minetest.register_tool(name, base_def)
	ctf_melee.registered_swords[name] = base_def
end

local slash_stab_anim_length = ctf_player.animation_time.stab_slash
local EXTRA_ANIM_LENGTH = {
	slash = slash_stab_anim_length * 0.5,
	stab = 0.1,
}

local SWOOSH_SOUND_DISTANCE = 8
local COMBAT_SOUND_DISTANCE = 16
local KNOCKBACK = {slash = 6, stab = 0}
local HIT_BOOST = 9

local function dopunch(target, attacker, ignores, attack_capabilities, dir, attack_interval)
	if target.ref:is_player() and not ignores[target.ref] and
	ctf_modebase:get_current_mode().can_punchplayer(attacker, target.ref) then
		ignores[target.ref] = true -- add to the table we were passed

		target.ref:punch(attacker, attack_interval, attack_capabilities, dir)

		minetest.sound_play("player_damage", {
			object = attacker,
			exclude_player = target.ref:get_player_name(),
			pitch = 0.8,
			gain = 0.4,
			max_hear_distance = COMBAT_SOUND_DISTANCE,
		}, true)

		return true
	end

	return false
end

local function slash_stab_sword_func(keypress, itemstack, user, pointed)
	local uname = user:get_player_name()
	local cooldown = attack_cooldown:get(uname)
	local anim = (keypress == "LMB" and "stab") or "slash"

	if cooldown then
		-- if the cooldown has <= 0.3 seconds left then let them queue another stab
		if anim == "stab" and cooldown._time - (os.clock() - cooldown.start_time) <= 0.3 then
			-- Don't queue a miss
			if not pointed or pointed.type ~= "object" then
				return
			end

			cooldown._on_end = function(self)
				local player = minetest.get_player_by_name(uname)

				if not player then return end

				local wielded = player:get_wielded_item()

				if wielded:get_name() ~= itemstack:get_name() then return end

				slash_stab_sword_func(keypress, wielded, user, pointed)
			end
		end

		return
	end

	local attack_interval = slash_stab_anim_length + EXTRA_ANIM_LENGTH[anim]

	ctf_player.set_stab_slash_anim(anim, user, EXTRA_ANIM_LENGTH[anim])

	attack_cooldown:set(uname, {
		_time = attack_interval,
		_on_end = function(self) -- Repeat attack if player is holding down the button
			local player = minetest.get_player_by_name(uname)

			if not player then return end

			local controls = player:get_player_control()
			local wielded = player:get_wielded_item()

			if wielded:get_name() == itemstack:get_name() and (controls.LMB or controls.RMB) then
				if not controls[keypress] then
					keypress = (keypress == "LMB") and "RMB" or "LMB"
				end

				slash_stab_sword_func(keypress, wielded, player, nil)
			end
		end,
	})

	local startpos = vector.offset(user:get_pos(), 0, user:get_properties().eye_height, 0)

	local def = itemstack:get_definition()
	local attack_capabilities = def.tool_capabilities

	local dir = user:get_look_dir()
	local user_kb_dir = vector.new(dir)

	local ignores = {[user] = true}
	local section = math.pi/12
	local hit_player = false
	local axis
	local rays

	attack_capabilities.damage_groups.knockback = KNOCKBACK[anim]

	axis = vector.cross(vector.new(dir.z, 0, -dir.x), dir)

	if pointed and pointed.type == "object" then
		hit_player = dopunch(pointed, user, ignores, attack_capabilities, dir, attack_interval) or hit_player

		pointed = true
	end

	if anim == "slash" then
		user_kb_dir = -user_kb_dir
		rays = {
			vector.rotate_around_axis(dir, axis,  section * 3),
			vector.rotate_around_axis(dir, axis,  section * 2),
			vector.rotate_around_axis(dir, axis,  section    ),

			vector.rotate_around_axis(dir, axis, -section * 3),
			vector.rotate_around_axis(dir, axis, -section * 2),
			vector.rotate_around_axis(dir, axis, -section    ),

			(pointed ~= true) and dir or nil,
		}

		minetest.sound_play("ctf_melee_whoosh", {
			object = user,
			pitch = 1.1,
			gain = 1.2,
			max_hear_distance = SWOOSH_SOUND_DISTANCE,
		}, true)
	else
		rays = {
			(pointed ~= true) and dir or nil,
			vector.rotate_around_axis(dir, axis, -section),
			vector.rotate_around_axis(dir, axis,  section),
		}

		minetest.sound_play("ctf_melee_whoosh", {
			object = user,
			gain = 1.1,
			max_hear_distance = SWOOSH_SOUND_DISTANCE,
		}, true)
	end

	user_kb_dir.y = math.max(math.min(user_kb_dir.y, 0.4), 0)

	for _, shootdir in ipairs(rays) do
		local ray = minetest.raycast(startpos, startpos + (shootdir * 4), true, false)

		minetest.add_particle({
			pos = startpos,
			velocity = shootdir * 44,
			expirationtime = 0.1,
			size = 5,
			collisiondetection = true,
			collision_removal = true,
			object_collision = false,
			texture = "ctf_melee_slash.png",
			glow = 5,
		})

		for hit in ray do
			if hit.type ~= "object" then break end

			hit_player = dopunch(hit, user, ignores, attack_capabilities, shootdir, attack_interval) or hit_player
		end
	end

	if hit_player then
		user:add_velocity(user_kb_dir * HIT_BOOST)
	end
end

function ctf_melee.register_sword(name, def)
	local base_def = {
		description = def.description,
		inventory_image = def.inventory_image,
		inventory_overlay = def.inventory_overlay,
		wield_image = def.wield_image,
		damage_groups = def.damage_groups,
		disable_mine_anim = true,
		tool_capabilities = {
			full_punch_interval = slash_stab_anim_length,
			max_drop_level=1,
			groupcaps={
				snappy={times={[1]=2.5, [2]=1.20, [3]=0.35}, uses=0, maxlevel=3},
			},
			punch_attack_uses = 0,
		},
		sound = {breaks = "default_tool_breaks"},
		groups = def.groups or {},
	}

	local damage_capabilities = base_def.tool_capabilities
	damage_capabilities.damage_groups = base_def.damage_groups

	base_def.groups.sword = 1

	local function rightclick_func(...)
		slash_stab_sword_func("RMB", ...)

		if def.rightclick_func then
			return def.rightclick_func(...)
		end
	end

	base_def.on_use = function(itemstack, user, pointed, ...)
		if pointed then
			if pointed.type == "object" then
				if not pointed.ref:is_player() then
					pointed.ref:punch(user, slash_stab_anim_length, damage_capabilities, vector.new())
					return
				end
			elseif pointed.type == "node" then
				local node = minetest.get_node(pointed.under)
				local node_on_punch = minetest.registered_nodes[node.name].on_punch

				if node_on_punch then
					node_on_punch(pointed.under, node, user, pointed)
				end
			end
		end

		slash_stab_sword_func("LMB", itemstack, user, pointed, ...)
	end

	base_def.on_place = function(itemstack, user, pointed, ...)
		local pointed_def = false
		local node

		if pointed and pointed.under then
			node = minetest.get_node(pointed.under)
			pointed_def = minetest.registered_nodes[node.name]
		end

		if pointed_def and pointed_def.on_rightclick then
			return minetest.item_place(itemstack, user, pointed)
		else
			return rightclick_func(itemstack, user, pointed, ...)
		end
	end

	base_def.on_secondary_use = rightclick_func

	minetest.register_tool(name, base_def)
	ctf_melee.registered_swords[name] = base_def
end

for mat, def in pairs(sword_mats) do
	ctf_melee.simple_register_sword("ctf_melee:sword_"..mat, def)

	minetest.register_alias_force("default:sword_"..mat, "ctf_melee:sword_"..mat)
end
