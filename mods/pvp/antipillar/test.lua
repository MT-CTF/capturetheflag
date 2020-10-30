local modname = minetest.get_current_modname()
local test_box = modname .. ":test_box"
local textures = {}
for index = 1, 6 do
    textures[index] = modname .. "_test_box.png"
end
minetest.register_entity(test_box, {
	initial_properties = {
		physical = false,
		pointable = true,
		visual = "cube",
		visual_size = { x = 1, y = 1, z = 1 },
		textures = textures,
		colors = {},
		use_texture_alpha = true,
		backface_culling = true,
		glow = 14,
		infotext = "Collisionbox",
		static_save = false,
		shaded = false
	}
})

local function visualize_box(pos, box)
    local obj = minetest.add_entity(vector.add(pos, {x = (box[1] + box[4]) / 2, y = (box[2] + box[5]) / 2, z = (box[3] + box[6]) / 2}), test_box)
    obj:set_properties{
        infotext = "Collisionbox: " .. minetest.write_json(box),
        visual_size = {x = box[4] - box[1], y = box[5] - box[2], z = box[6] - box[3]}
    }
end

return visualize_box