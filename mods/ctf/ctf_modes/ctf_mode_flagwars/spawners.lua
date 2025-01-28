local function register_spawner(tiles, item, node_suffix, interval)
	local spawn = false
	minetest.register_node("ctf_mode_flagwars:spawner_"..node_suffix, {
		tiles = tiles,
		overlay_tiles = { name = "ctf_mode_flagwars_spawner_overlay.png" },
		walkable = true,
		pointable = true,
		diggable = false,
		on_construct = function(pos)
			local function spawnfn()
				pos.y = pos.y + 1
				minetest.add_item(pos, item)
				if spawn then
					minetest.after(interval, spawnfn)
				end
			end
			spawn = true
			spawnfn()
		end,
		on_destruct = function(pos)
			spawn = false
		end,
	})
end

register_spawner({ name = "default_gold_block.png" }, "default:ingot_gold", "gold", 1)
