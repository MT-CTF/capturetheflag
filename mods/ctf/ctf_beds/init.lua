local modname = core.get_current_modname()
loadfile(core.get_modpath(modname) .. "/exported.lua")(function(def)

		local orig = def._raw_name
		local suff = orig:gsub("beds:", "")
		local myname = modname .. ":" .. suff -- e.g. ctf_beds:fancy_bed_bottom
		local bedname = myname:gsub("_top", ""):gsub("_bottom", "") -- the bed name without suff e.g. ctf_beds:fancy_bed

		-- Removes a node without calling on on_destruct()
		-- We use this to mess with bed nodes without causing unwanted recursion.
		local function remove_no_destruct(pos)
			core.swap_node(pos, {name = "air"})
			core.remove_node(pos) -- Now clear the meta
			core.check_for_falling(pos)
		end

		local function destruct_bed(pos, n)
			local node = core.get_node(pos)
			local other
			if n == 2 then
				local dir = core.facedir_to_dir(node.param2)
				other = vector.subtract(pos, dir)
			elseif n == 1 then
				local dir = core.facedir_to_dir(node.param2)
				other = vector.add(pos, dir)
			end
			local oname = core.get_node(other).name
			if core.get_item_group(oname, "bed") ~= 0 then
			   remove_no_destruct(other)
			end
		end

		if def.type ~= "node" then
			def.type = "node"
			def.tiles = {def.inventory_image}
		end

		if string.find(def._raw_name, "bottom") then
			def.drawtype = "nodebox"
			def.paramtype = "light"
			def.paramtype2 = "facedir"
			def.selection_box = def.selection_box
			def.node_box = def.node_box
			def.groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 3, bed = 1}
			def.on_place = function(itemstack, placer, pointed_thing)
				local under = pointed_thing.under
				local node = core.get_node(under)
				local udef = core.registered_nodes[node.name]
				if udef and udef.on_rightclick and
						not (placer and placer:is_player() and
						placer:get_player_control().sneak) then
					return udef.on_rightclick(under, node, placer, itemstack,
						pointed_thing) or itemstack
				end

				local pos
				if udef and udef.buildable_to then
					pos = under
				else
					pos = pointed_thing.above
				end

				local player_name = placer and placer:get_player_name() or ""

				if core.is_protected(pos, player_name) and
						not core.check_player_privs(player_name, "protection_bypass") then
					core.record_protection_violation(pos, player_name)
					return itemstack
				end

				local node_def = core.registered_nodes[core.get_node(pos).name]
				if not node_def or not node_def.buildable_to then
					return itemstack
				end

				local dir = placer and placer:get_look_dir() and
					core.dir_to_facedir(placer:get_look_dir()) or 0
				local botpos = vector.add(pos, core.facedir_to_dir(dir))

				if core.is_protected(botpos, player_name) and
						not core.check_player_privs(player_name, "protection_bypass") then
					core.record_protection_violation(botpos, player_name)
					return itemstack
				end

				local botdef = core.registered_nodes[core.get_node(botpos).name]
				if not botdef or not botdef.buildable_to then
					return itemstack
				end

				core.set_node(pos, {name = bedname .. "_bottom", param2 = dir})
				core.set_node(botpos, {name = bedname .. "_top", param2 = dir})

				if not core.is_creative_enabled(player_name) then
					itemstack:take_item()
				end
				return itemstack
			end
			def.on_rotate = function(pos, node, user, _, new_param2)
				local dir = core.facedir_to_dir(node.param2)
				-- old position of the top node
				local p = vector.add(pos, dir)
				local node2 = core.get_node_or_nil(p)
				if not node2 or core.get_item_group(node2.name, "bed") ~= 2 or node.param2 ~= node2.param2 then
					return false
				end

				if core.is_protected(p, user:get_player_name()) then
					core.record_protection_violation(p, user:get_player_name())
					return false
				end

				if new_param2 % 32 > 3 then
					return false
				end
				-- new position of the top node
				local newp = vector.add(pos, core.facedir_to_dir(new_param2))
				local node3 = core.get_node_or_nil(newp)
				local node_def = node3 and core.registered_nodes[node3.name]
				if not node_def or not node_def.buildable_to then
					return false
				end

				if core.is_protected(newp, user:get_player_name()) then
					core.record_protection_violation(newp, user:get_player_name())
					return false
				end

				node.param2 = new_param2
				remove_no_destruct(p)
				core.set_node(pos, node)
				core.set_node(newp, {name = bedname .. "_top", param2 = new_param2})
				return true
			end
			def.on_destruct = function(pos)
				destruct_bed(pos, 1)
			end
		end

		if string.find(def._raw_name, "top") then
			def.node_box = def.node_box
			def.is_ground_content = false
			def.pointable = false
			def.groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 3, bed = 2, not_in_creative_inventory = 1}
			def.drop = bedname .. "_bottom"
			def.on_destruct = function(pos)
				destruct_bed(pos, 2)
			end
		end

		--dont register alias and item for bed_red (see exported.lua), they are not needed
		if not string.find(def._raw_name, "red") then
			core.register_item(myname, def)
		end

		if not string.find(def._raw_name, "red") then
			core.register_alias_force(bedname, bedname .. "_bottom")
		end
	end)