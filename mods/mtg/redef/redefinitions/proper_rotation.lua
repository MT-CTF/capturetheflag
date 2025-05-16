local override_item = core.override_item
local pointed_thing_to_face_pos = core.pointed_thing_to_face_pos
local dir_to_facedir = core.dir_to_facedir
local is_creative_enabled = core.is_creative_enabled
local item_place_node = core.item_place_node

local stairs = {}
local slabs = {}
local slopes = {}


-- Correct stairs placement
--
-- Derived from the original stairs on_place function of Minetest Game.
--
-- @param itemstack An itemstack according to Luanti API
-- @param placer A placer object according to Luanti API
-- @param pointed_thing A pointed_thing according to Luanti API
-- @return mixed itemstack and position according to Luanti API
local properly_rotate = function (itemstack, placer, pointed_thing)
    local under = pointed_thing.under
    local above = pointed_thing.above
    local param2 = 0

    if placer then
        local placer_pos = placer:get_pos()
        local finepos = pointed_thing_to_face_pos(placer, pointed_thing)
        local fpos = finepos.y % 1

        local under_above = under.y - 1 == above.y
        local fpos_perimeter = (fpos > 0 and fpos < 0.5)
        local fpos_limit = (fpos < -0.5 and fpos > -0.999999999)

        if placer_pos then
            param2 = dir_to_facedir(vector.subtract(above, placer_pos))
        end

        if under_above or fpos_perimeter or fpos_limit then
            param2 = param2 + 20
            if param2 == 21 then
                param2 = 23
            elseif param2 == 23 then
                param2 = 21
            end
        end
    end

    return core.item_place(itemstack, placer, pointed_thing, param2)
end


-- Correct slabs placement
--
-- Derived from the original stairs on_place function of Minetest Game.
--
-- @param itemstack An itemstack according to LuantI API
-- @param placer A placer object according to Luanti API
-- @param pointed_thing A pointed_thing according to Luanti API
-- @return mixed itemstack and position according to Luanti API
local on_place_slabs = function (itemstack, placer, pointed_thing)
    local under = core.get_node(pointed_thing.under)
    local wield_item = itemstack:get_name()
    local player_name = placer and placer:get_player_name() or ''

    -- Special behavior if placed on a slab
    if under and under.name:find(':slab_') then
        local pt_above = pointed_thing.above
        local pt_under = pointed_thing.under
        local fdir = dir_to_facedir(vector.subtract(pt_above, pt_under), true)
        local p2 = under.param2

        -- Slab placement based on upside-down slabs or below slabs
        --
        --     ┌────────┐
        --     │        │
        --     ┢━━━━━━━━┪    <-- Slab A (bottom half of the node seen sideways)
        --     ┃        ┃
        -- ┈┈┈┈┣━━━━━━━━┫┈┈┈┈
        --     ┃        ┃
        --     ┡━━━━━━━━┩    <-- Slab B (top half of the node, seen sideways)
        --     │        │
        --     └────────┘
        --
        -- Slabs A and B are rotated according slab B or A on placement so that
        -- slabs placed on regular slabs from below automatically become
        -- upside-down slabs and slabs placed on top of upside-down slabs are
        -- not rotated into the same position.
        if p2 >= 20 and fdir == 8 then p2 = p2 - 20 end -- Slab A rotation
        if p2 <= 3 and fdir == 4 then p2 = p2 + 20 end  -- Slab B rotation

        -- Place node usind the calculated rotation
        item_place_node(ItemStack(wield_item), placer, pointed_thing, p2)

        -- Remove one item if not in creative and return the itemstack
        if not is_creative_enabled(player_name) then itemstack:take_item() end
        return itemstack
    end

    -- When not placed on a slab just properly rotate the slab
    return properly_rotate(itemstack, placer, pointed_thing)
end



-- Determine all stairs and slabs and put them into the respective tables.
for name,definition in pairs(core.registered_nodes) do
    local from_moreblocks = definition.mod_origin == 'moreblocks'
    local from_bakedclay = definition.mod_origin == 'bakedclay'
    local mod_origin = from_moreblocks or from_bakedclay

    local stair = string.match(name, ':stair_') ~= nil
    local slab = string.match(name, ':slab_') ~= nil
    local slope = string.match(name, ':slope_') ~= nil

    if stair and mod_origin then table.insert(stairs, name) end
    if slab and mod_origin then table.insert(slabs, name) end
    if slope and mod_origin then table.insert(slopes, name) end
end


-- Iterate over all stairs and override the broken on_place function.
for _,name in pairs(stairs) do
    override_item(name, {
        on_place = function (itemstack, placer, pointed_thing)
            if pointed_thing.type ~= "node" then return itemstack end
            return properly_rotate(itemstack, placer, pointed_thing)
        end
    })
end


-- Iterate over all slopes and override the broken on_place function.
for _,name in pairs(slopes) do
    override_item(name, {
        on_place = function (itemstack, placer, pointed_thing)
            if pointed_thing.type ~= "node" then return itemstack end
            return properly_rotate(itemstack, placer, pointed_thing)
        end
    })
end


-- Iterate over all slabs and override the broken on_place function.
for _,name in pairs(slabs) do
    override_item(name, {
        on_place = function (itemstack, placer, pointed_thing)
            return on_place_slabs(itemstack, placer, pointed_thing)
        end
    })
end
