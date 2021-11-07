function ctf_map.announce_map(map)
	local msg = (minetest.colorize("#fcdb05", "Map: ") .. minetest.colorize("#f49200", map.name) ..
	minetest.colorize("#fcdb05", " by ") .. minetest.colorize("#f49200", map.author))
	if map.hint then
		msg = msg .. "\n" .. minetest.colorize("#f49200", map.hint)
	end
	minetest.chat_send_all(msg)
	if minetest.global_exists("irc") and irc.connected then
		irc:say("Map: " .. map.name)
	end
end

function ctf_map.place_map(mapmeta, callback)
	local dirname = mapmeta.dirname
	local schempath = ctf_map.maps_dir .. dirname .. "/map.mts"

	ctf_map.emerge_with_callbacks(nil, mapmeta.pos1, mapmeta.pos2, function(ctx)
		local rotation = (mapmeta.rotation and mapmeta.rotation ~= "z") and "90" or "0"
		local res = minetest.place_schematic(mapmeta.pos1, schempath, rotation)

		minetest.log("action", string.format("Placed map %s in %.2fms", dirname, (os.clock() - ctx.start_time) * 1000))

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

		minetest.after(3, function()
			for _, object_drop in pairs(minetest.get_objects_in_area(mapmeta.pos1, mapmeta.pos2)) do
				if not object_drop:is_player() then
					local drop = object_drop:get_luaentity()

					if drop and drop.name == "__builtin:item" then
						object_drop:remove()
					end
				end
			end
		end)

		minetest.after(7, function()
			minetest.fix_light(mapmeta.pos1, mapmeta.pos2)
		end)

		assert(res, "Unable to place schematic, does the MTS file exist? Path: " .. schempath)

		ctf_map.current_map = mapmeta

		callback()
	end)
end

--
--- VOXELMANIP FUNCTIONS
--

-- Takes [mapmeta] or [pos1, pos2] arguments
function ctf_map.remove_barrier(mapmeta, pos2)
	local pos1 = mapmeta

	if not pos2 then
		pos1, pos2 = mapmeta.barrier_area.pos1, mapmeta.barrier_area.pos2
	end

	local vm = VoxelManip()
	pos1, pos2 = vm:read_from_map(pos1, pos2)

	local data = vm:get_data()
	local Nx = pos2.x - pos1.x + 1
	local Ny = pos2.y - pos1.y + 1

	for z = pos1.z, pos2.z do
		for y = pos1.y, pos2.y do
			for x = pos1.x, pos2.x do
				local vi = (z - pos1.z) * Ny * Nx + (y - pos1.y) * Nx + (x - pos1.x) + 1

				for barriernode_id, replacement_id in pairs(ctf_map.barrier_nodes) do
					if data[vi] == barriernode_id then
						data[vi] = replacement_id
						break
					end
				end
			end
		end
	end

	vm:set_data(data)
	vm:update_liquids()
	vm:write_to_map(false)
end

local ID_AIR = minetest.CONTENT_AIR
local ID_IGNORE = minetest.CONTENT_IGNORE
local DEFAULT_CHEST_AMOUNT = ctf_map.DEFAULT_CHEST_AMOUNT
local CHEST_ID = minetest.get_content_id("ctf_map:chest")
local ID_WATER = minetest.get_content_id("default:water_source")
local insert = table.insert
function ctf_map.place_chests(mapmeta, pos2, amount)
	local pos1 = mapmeta
	local pos_list

	if not pos2 then -- place_chests(mapmeta) was called
		pos_list = mapmeta.chests
		pos1, pos2 = mapmeta.pos1, mapmeta.pos2
	else -- place_chests(pos1, pos2, amount?) was called
		pos_list = {{pos1 = pos1, pos2 = pos2, amount = amount or DEFAULT_CHEST_AMOUNT}}
	end

	local vm = VoxelManip()
	pos1, pos2 = vm:read_from_map(pos1, pos2)

	local data = vm:get_data()
	local Nx = pos2.x - pos1.x + 1
	local Ny = pos2.y - pos1.y + 1

	for _, a in pairs(pos_list) do
		local place_positions = {}

		for z = a.pos1.z, a.pos2.z, (a.pos1.z <= a.pos2.z) and 1 or -1 do
			for y = a.pos1.y, a.pos2.y, (a.pos1.y <= a.pos2.y) and 1 or -1 do
				for x = a.pos1.x, a.pos2.x, (a.pos1.x <= a.pos2.x) and 1 or -1 do
					local vi = (z - pos1.z) * Ny * Nx + (y - pos1.y) * Nx + (x - pos1.x) + 1
					local id_below = data[(z - pos1.z) * Ny * Nx + (y-1 - pos1.y) * Nx + (x - pos1.x) + 1]
					local id_above = data[(z - pos1.z) * Ny * Nx + (y+1 - pos1.y) * Nx + (x - pos1.x) + 1]

					if (data[vi] == ID_AIR or data[vi] == ID_WATER) and
					id_below ~= ID_AIR and id_below ~= ID_IGNORE and id_below ~= ID_WATER and
					(id_above == ID_AIR or id_above == ID_WATER) then
						insert(place_positions, vi)
					end
				end
			end
		end

		if place_positions and #place_positions > 1 then
			for i = 1, a.amount, 1 do
				local idx = math.random(1, #place_positions)

				data[place_positions[idx]] = CHEST_ID

				table.remove(place_positions, idx)
			end
		else
			minetest.log("error", "Something went wrong with chest placement")
		end
	end

	vm:set_data(data)
	vm:update_liquids()
	vm:write_to_map(false)
end
