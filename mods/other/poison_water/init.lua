-- Register the Poisonous Water node
minetest.register_node("poison_water:poisonous_water", {
    description = "Poisonous Water",
    drawtype = "liquid",
    tiles = {
        {
            name = "default_water_source_animated.png",
            animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
        }
    },
    special_tiles = {
        {
            name = "default_water_source_animated.png",
            animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
            backface_culling = false,
        }
    },
    paramtype = "light",
    walkable = false,
    pointable = true,
    diggable = true,
    buildable_to = true,
    liquidtype = "source",
    liquid_alternative_flowing = "poison_water:poisonous_water_flowing",
    liquid_alternative_source = "poison_water:poisonous_water",
    liquid_viscosity = 1,
    damage_per_second = 2, -- Deals 1-2 HP damage per second
    groups = {liquid = 3, puts_out_fire = 1},
    sounds = default.node_sound_water_defaults(),
    color = "#00FF00", -- Green tint
    post_effect_color = {a = 191, r = 0, g = 255, b = 0}, -- Greenish glow
})

-- Register the flowing variant of Poisonous Water
minetest.register_node("poison_water:poisonous_water_flowing", {
    description = "Flowing Poisonous Water",
    drawtype = "flowingliquid",
    tiles = {"default_water.png"}, -- Static texture for the inventory
    special_tiles = {
        {
            name = "default_water_flowing_animated.png",
            animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
            backface_culling = false,
        },
        {
            name = "default_water_flowing_animated.png",
            animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
            backface_culling = true,
        },
    },
    paramtype = "light",
    paramtype2 = "flowingliquid",
    walkable = false,
    pointable = true,
    diggable = true,
    buildable_to = true,
    liquidtype = "flowing",
    liquid_alternative_flowing = "poison_water:poisonous_water_flowing",
    liquid_alternative_source = "poison_water:poisonous_water",
    liquid_viscosity = 1,
    damage_per_second = 2, -- Deals 1-2 HP damage per second
    groups = {liquid = 3, puts_out_fire = 1, not_in_creative_inventory = 1},
    sounds = default.node_sound_water_defaults(),
    color = "#00FF00", -- Green tint
    post_effect_color = {a = 191, r = 0, g = 255, b = 0}, -- Greenish glow
})
-- Poisonous Water Bucket (requires the bucket mod)
if minetest.get_modpath("bucket") then
    bucket.register_liquid(
        "poison_water:poisonous_water",
        "poison_water:poisonous_water_flowing",
        "poison_water:bucket_poisonous_water",
        "bucket_poision_water.png", -- Green tinted bucket texture
        "Poisonous Water Bucket"
    )

    -- Register crafting to empty the bucket
    minetest.register_craft({
        type = "shapeless",
        output = "bucket:bucket_empty",
        recipe = {"poison_water:bucket_poisonous_water"},
        replacements = {{"poison_water:bucket_poisonous_water", "bucket:bucket_empty"}},
    })
end


-- Add ABM to harm players standing in Poisonous Water

-- minetest.register_abm({
--     label = "Poisonous Water Damage",
--     nodenames = {"poison_water:poisonous_water", "poison_water:poisonous_water_flowing"},
--     interval = 1.0,
--     chance = 1,
--     action = function(pos, node, active_object_count, active_object_count_wider)
--         local objects = minetest.get_objects_inside_radius(pos, 1)
--         for _, obj in ipairs(objects) do
--             if obj:is_player() then
--                 obj:set_hp(obj:get_hp() - 2) -- Deals 2 HP damage
--             end
--         end
--     end,
-- })
