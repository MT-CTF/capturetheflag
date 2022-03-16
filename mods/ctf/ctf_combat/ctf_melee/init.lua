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
local HIT_KNOCKBACK = 10
local MISS_KNOCKBACK = 5
local SLASH_KNOCKBACK_MULT = 6

local function slash_stab_sword_func(keypress, itemstack, user, pointed)
	local uname = user:get_player_name()

	if attack_cooldown:get(uname) then
		local a_c = attack_cooldown:get(uname)

		a_c.keypress = keypress
		a_c._on_end = function(self)
			local player = minetest.get_player_by_name(uname)

			if not player then return end

			local controls = player:get_player_control()
			local next_keypress = self.keypress

			if controls.LMB or controls.RMB then
				local item = player:get_wielded_item()
				if item:get_name() == itemstack:get_name() then
					-- player switched attack
					if not controls[next_keypress] then
						if next_keypress == "LMB" then
							next_keypress = "RMB"
						else
							next_keypress = "LMB"
						end
					end

					slash_stab_sword_func(next_keypress, itemstack, user, pointed)
				end
			end
		end

		return
	end

	local anim = (keypress == "LMB" and "stab") or "slash"

	ctf_player.set_stab_slash_anim(anim, user, EXTRA_ANIM_LENGTH[anim])

	attack_cooldown:set(uname, {
		keypress = keypress,
		_time = slash_stab_anim_length + EXTRA_ANIM_LENGTH[anim],
	})

	local dir = user:get_look_dir()
	local def = itemstack:get_definition()
	local attack_capabilities = def.tool_capabilities
	local user_kb_dir = vector.new(dir)

	attack_capabilities.damage_groups = def.damage_groups

	if anim == "slash" then
		local section = math.pi/12
		local axis

		user_kb_dir = -user_kb_dir
		user_kb_dir.y = math.max(math.min(user_kb_dir.y, 0.4), 0)

		axis = vector.cross(vector.new(dir.z, 0, -dir.x), dir)

		local rays = {
			vector.rotate_around_axis(dir, axis, -section * 3),
			vector.rotate_around_axis(dir, axis, -section * 2),
			vector.rotate_around_axis(dir, axis, -section),
			dir,
			vector.rotate_around_axis(dir, axis, section),
			vector.rotate_around_axis(dir, axis, section * 2),
			vector.rotate_around_axis(dir, axis, section * 3),
		}

		local startpos = vector.offset(user:get_pos(), 0, user:get_properties().eye_height, 0)
		local ignores = {[user] = true}
		local hit_player = false
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

				if hit.ref:is_player() and not ignores[hit.ref] then
					ignores[hit.ref] = true
					hit_player = true

					attack_capabilities.damage_groups.knockback = SLASH_KNOCKBACK_MULT

					hit.ref:punch(user, slash_stab_anim_length + EXTRA_ANIM_LENGTH[anim], attack_capabilities, shootdir)

					minetest.sound_play("player_damage", {
						object = user,
						exclude_player = hit.ref:get_player_name(),
						pitch = 0.8,
						gain = 0.4,
						max_hear_distance = 10,
					}, true)
				end
			end
		end

		if hit_player then
			user:add_velocity(user_kb_dir * HIT_KNOCKBACK)

			minetest.sound_play("ctf_melee_whoosh", {
				object = user,
				pitch = 1.1,
				gain = 1.2,
				max_hear_distance = 4,
			}, true)
		else
			user:add_velocity(user_kb_dir * MISS_KNOCKBACK)

			minetest.sound_play("ctf_melee_whoosh", {
				object = user,
				pitch = 1.1,
				gain = 0.5,
				max_hear_distance = 4,
			}, true)
		end
	else
		user_kb_dir.y = math.max(math.min(user_kb_dir.y, 0.4), 0)

		if pointed and pointed.type == "object" then
			attack_capabilities.damage_groups.knockback = 0 -- This attack is for catching people
			pointed.ref:punch(user, slash_stab_anim_length + EXTRA_ANIM_LENGTH[anim], attack_capabilities, dir)
			user:add_velocity(user_kb_dir * HIT_KNOCKBACK)

			minetest.sound_play("ctf_melee_whoosh", {
				object = user,
				max_hear_distance = 3,
				gain = 1.2,
			}, true)

			minetest.sound_play("player_damage", {
				object = user,
				exclude_player = pointed.ref:get_player_name(),
				pitch = 0.9,
				gain = 0.3,
				max_hear_distance = 8,
			}, true)
		else
			user:add_velocity(user_kb_dir * MISS_KNOCKBACK)

			minetest.sound_play("ctf_melee_whoosh", {
				object = user,
				gain = 0.5,
				max_hear_distance = 3,
			}, true)
		end
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
			if pointed.type == "object" and not pointed.ref:is_player() then
				pointed.ref:punch(user, slash_stab_anim_length, damage_capabilities, vector.new())
				return
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
