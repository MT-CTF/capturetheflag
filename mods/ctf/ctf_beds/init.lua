local modname = minetest.get_current_modname()
loadfile(minetest.get_modpath(modname) .. "/exported.lua")(function(def)

		local orig = def._raw_name
		local suff = orig:gsub("beds:", "")
		local myname = modname .. ":" .. suff -- e.g. ctf_beds:fancy_bed_bottom
		local bedname = myname:gsub("_top", ""):gsub("_bottom", "") -- the bed name without suff e.g. ctf_beds:fancy_bed

		-- Removes a node without calling on on_destruct()
		-- We use this to mess with bed nodes without causing unwanted recursion.
		local function remove_no_destruct(pos)
			minetest.swap_node(pos, {name = "air"})
			minetest.remove_node(pos) -- Now clear the meta
			minetest.check_for_falling(pos)
		end

		local function destruct_bed(pos, n)
			local node = minetest.get_node(pos)
			local other
			if n == 2 then
				local dir = minetest.facedir_to_dir(node.param2)
				other = vector.subtract(pos, dir)
			elseif n == 1 then
				local dir = minetest.facedir_to_dir(node.param2)
				other = vector.add(pos, dir)
			end
			local oname = minetest.get_node(other).name
			if minetest.get_item_group(oname, "bed") ~= 0 then
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
				local node = minetest.get_node(under)
				local udef = minetest.registered_nodes[node.name]
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

				if minetest.is_protected(pos, player_name) and
						not minetest.check_player_privs(player_name, "protection_bypass") then
					minetest.record_protection_violation(pos, player_name)
					return itemstack
				end

				local node_def = minetest.registered_nodes[minetest.get_node(pos).name]
				if not node_def or not node_def.buildable_to then
					return itemstack
				end

				local dir = placer and placer:get_look_dir() and
					minetest.dir_to_facedir(placer:get_look_dir()) or 0
				local botpos = vector.add(pos, minetest.facedir_to_dir(dir))

				if minetest.is_protected(botpos, player_name) and
						not minetest.check_player_privs(player_name, "protection_bypass") then
					minetest.record_protection_violation(botpos, player_name)
					return itemstack
				end

				local botdef = minetest.registered_nodes[minetest.get_node(botpos).name]
				if not botdef or not botdef.buildable_to then
					return itemstack
				end

				minetest.set_node(pos, {name = bedname .. "_bottom", param2 = dir})
				minetest.set_node(botpos, {name = bedname .. "_top", param2 = dir})
				
				if not minetest.is_creative_enabled(player_name) then
					itemstack:take_item()
				end
				return itemstack
			end
			def.on_rotate = function(pos, node, user, _, new_param2)
				local dir = minetest.facedir_to_dir(node.param2)
				-- old position of the top node
				local p = vector.add(pos, dir)
				local node2 = minetest.get_node_or_nil(p)
				if not node2 or minetest.get_item_group(node2.name, "bed") ~= 2 or node.param2 ~= node2.param2 then
					return false
				end

				if minetest.is_protected(p, user:get_player_name()) then
					minetest.record_protection_violation(p, user:get_player_name())
					return false
				end

				if new_param2 % 32 > 3 then
					return false
				end
				-- new position of the top node
				local newp = vector.add(pos, minetest.facedir_to_dir(new_param2))
				local node3 = minetest.get_node_or_nil(newp)
				local node_def = node3 and minetest.registered_nodes[node3.name]
				if not node_def or not node_def.buildable_to then
					return false
				end

				if minetest.is_protected(newp, user:get_player_name()) then
					minetest.record_protection_violation(newp, user:get_player_name())
					return false
				end

				node.param2 = new_param2
				remove_no_destruct(p)
				minetest.set_node(pos, node)
				minetest.set_node(newp, {name = bedname .. "_top", param2 = new_param2})
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
			minetest.register_item(myname, def)
		end

		if not string.find(def._raw_name, "red") then
			minetest.register_alias_force(bedname, bedname .. "_bottom")
		end
	end)