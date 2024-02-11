function ctf_map.announce_map(map)
	local msg = (minetest.colorize("#fcdb05", "Map: ") .. minetest.colorize("#f49200", map.name) ..
	minetest.colorize("#fcdb05", " by ") .. minetest.colorize("#f49200", map.author))
	if map.hint and map.hint ~= "" then
		msg = msg .. "\n" .. minetest.colorize("#f49200", map.hint)
	end
	minetest.chat_send_all(msg)
end

function ctf_map.place_map(mapmeta, callback)
	local dirname = mapmeta.dirname
	local schempath = ctf_map.maps_dir .. dirname .. "/map.mts"

	ctf_map.emerge_with_callbacks(nil, mapmeta.pos1, mapmeta.pos2, function(ctx)
		local rotation = (mapmeta.rotation and mapmeta.rotation ~= "z") and "90" or "0"
		local res = minetest.place_schematic(mapmeta.pos1, schempath, rotation, {["ctf_map:chest"] = "air"})

		minetest.log("action", string.format(
			"Placed map %s in %.2fs", dirname, (minetest.get_us_time() - ctx.start_time) / 1000000
		))

		for name, def in pairs(mapmeta.teams) do
			local p = def.flag_pos

			local node = minetest.get_node(p)

			if node.name ~= "ctf_modebase:flag" then
				minetest.log("error", name.."'s flag was set incorrectly, or there is no flag node placed")
			else
				minetest.set_node(vector.offset(p, 0, 1, 0), {name="ctf_modebase:flag_top_"..name, param2 = node.param2})

				-- Place flag base if needed
				if tonumber(mapmeta.map_version or "0") < 2 then
					for x = -2, 2 do
						for z = -2, 2 do
							minetest.set_node(vector.offset(p, x, -1, z), {name = def.base_node or "ctf_map:cobble"})
						end
					end
				end
			end
		end

		minetest.fix_light(mapmeta.pos1, mapmeta.pos2)

		assert(res, "Unable to place schematic, does the MTS file exist? Path: " .. schempath)

		ctf_map.current_map = mapmeta

		callback()
	end)
end

--
--- VOXELMANIP FUNCTIONS
--

local ID_IGNORE = minetest.CONTENT_IGNORE
local ID_AIR = minetest.CONTENT_AIR
local ID_WATER = minetest.get_content_id("default:water_source")

---@param mapmeta table Map meta table
---@param callback function
function ctf_map.remove_barrier(mapmeta, callback)
	if not mapmeta.barriers then
		minetest.log("action", "Clearing barriers using mapmeta.barrier_area")

		local pos1, pos2 = mapmeta.barrier_area.pos1, mapmeta.barrier_area.pos2

		local vm = VoxelManip(pos1, pos2)
		local data = vm:get_data()

		for i, id in pairs(data) do
			local done = false

			for barriernode_id, replacement_id in pairs(ctf_map.barrier_nodes) do
				if id == barriernode_id then

					data[i] = replacement_id
					done = true
					break
				end
			end

			if not done then
				data[i] = ID_IGNORE
			end
		end

		vm:set_data(data)
		vm:write_to_map(false)

		minetest.after(0.1, function()
			local vm2 = VoxelManip(pos1, pos2)
			vm2:update_liquids()
		end)
	else
		local i = 0
		for _, barrier_area in pairs(mapmeta.barriers) do
			minetest.after(i, function()
				local vm = VoxelManip()
				vm:read_from_map(barrier_area.pos1, barrier_area.pos2)

				local data = vm:get_data()
				assert(#data == barrier_area.max)
				for idx in pairs(data) do
					data[idx] = barrier_area.reps[idx] or ID_IGNORE
				end

				vm:set_data(data)
				vm:write_to_map(false)
			end)

			i = i + 0.04
		end

		minetest.after(i - 0.04, function()
			local vm = VoxelManip(mapmeta.pos1, mapmeta.pos2)
			vm:update_liquids()

			callback()
		end)

		return
	end

	callback()
end


local ID_CHEST = minetest.get_content_id("ctf_map:chest")
local function get_place_positions(a, data, pos1, pos2)
	if a.amount <= 0 then return {} end

	local Nx = pos2.x - pos1.x + 1
	local Ny = pos2.y - pos1.y + 1

	local Sx = math.min(a.pos1.x, a.pos2.x)
	local Mx = math.max(a.pos1.x, a.pos2.x) - Sx + 1

	local Sy = math.min(a.pos1.y, a.pos2.y)
	local My = math.max(a.pos1.y, a.pos2.y) - Sy + 1

	local Sz = math.min(a.pos1.z, a.pos2.z)
	local Mz = math.max(a.pos1.z, a.pos2.z) - Sz + 1

	local ret = {}
	local random_state = {}
	local random_count = Mx * My * Mz

	local math_random = math.random
	local math_floor = math.floor
	local table_insert = table.insert

	while random_count > 0 do
		local pos = math_random(1, random_count)
		pos = random_state[pos] or pos

		local x = pos % Mx + Sx
		local y = math_floor(pos / Mx) % My + Sy
		local z = math_floor(pos / My / Mx) + Sz

		local vi = (z - pos1.z) * Ny * Nx + (y - pos1.y) * Nx + (x - pos1.x) + 1
		local id_below = data[(z - pos1.z) * Ny * Nx + (y - 1 - pos1.y) * Nx + (x - pos1.x) + 1]
		local id_above = data[(z - pos1.z) * Ny * Nx + (y + 1 - pos1.y) * Nx + (x - pos1.x) + 1]

		if (data[vi] == ID_AIR or data[vi] == ID_WATER) and
			id_below ~= ID_AIR and id_below ~= ID_IGNORE and id_below ~= ID_WATER and
			(id_above == ID_AIR or id_above == ID_WATER)
		then
			table_insert(ret, {vi=vi, x=x, y=y, z=z})
			if #ret >= a.amount then
				return ret
			end
		end

		random_state[pos] = random_state[random_count] or random_count
		random_state[random_count] = nil
		random_count = random_count - 1
	end

	return ret
end

local function prepare_nodes(pos1, pos2, data, team_chest_items, blacklisted_nodes)
	local Nx = pos2.x - pos1.x + 1
	local Ny = pos2.y - pos1.y + 1

	local math_floor = math.floor

	local nodes = {}
	for _, node in ipairs(blacklisted_nodes) do
		nodes[minetest.get_content_id(node)] = false
	end

	for _, team in ipairs(ctf_teams.teamlist) do
		local node = "ctf_teams:chest_" .. team
		nodes[minetest.get_content_id(node)] = minetest.registered_nodes[node]
	end

	for i, v in ipairs(data) do
		local op = nodes[v]
		if op == false then
			data[i] = ID_AIR
		elseif op then
			-- it's a team chest
			local x = (i - 1) % Nx + pos1.x
			local y = math_floor((i - 1) / Nx) % Ny + pos1.y
			local z = math_floor((i - 1) / Ny / Nx) + pos1.z
			local pos = {x=x, y=y, z=z}

			op.on_construct(pos)

			local inv = minetest.get_meta(pos):get_inventory()
			inv:set_list("main", team_chest_items)
			inv:set_list("pro", {})
			inv:set_list("helper", {})
		end
	end
end

local function place_treasure_chests(mapmeta, pos1, pos2, data, param2_data, treasurefy_node_callback)
	for i, a in pairs(mapmeta.chests) do
		local place_positions = get_place_positions(a, data, pos1, pos2)

		for _, pos in ipairs(place_positions) do
			data[pos.vi] = ID_CHEST
			param2_data[pos.vi] = 0

			-- Treasurefy
			minetest.registered_nodes["ctf_map:chest"].on_construct(pos)

			local inv = minetest.get_meta(pos):get_inventory()
			inv:set_list("main", {})
			if treasurefy_node_callback then
				treasurefy_node_callback(inv)
			end
		end

		if #place_positions < a.amount then
			minetest.log("error",
				string.format("[MAP] Couldn't place %d of the %d chests needed to place in zone %d",
					a.amount - #place_positions,
					a.amount,
					i
				)
			)
		end
	end
end

function ctf_map.prepare_map_nodes(mapmeta, treasurefy_node_callback, team_chest_items, blacklisted_nodes)
	local vm = VoxelManip()
	local pos1, pos2 = vm:read_from_map(mapmeta.pos1, mapmeta.pos2)

	local data = vm:get_data()
	local param2_data = vm:get_param2_data()

	prepare_nodes(pos1, pos2, data, team_chest_items, blacklisted_nodes)
	place_treasure_chests(mapmeta, pos1, pos2, data, param2_data, treasurefy_node_callback)

	vm:set_data(data)
	vm:set_param2_data(param2_data)
	vm:update_liquids()
	vm:write_to_map(false)
end
