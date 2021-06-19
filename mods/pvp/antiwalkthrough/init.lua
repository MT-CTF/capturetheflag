-- Create a collisionbox which in total is a regular cube - but if inside, you will be stuck between 6 "faces"
local collisionbox = {
    type = "fixed",
    fixed = {}
}
local boxes = collisionbox.fixed
for i = 1, 3 do
    boxes[i] = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
    boxes[i][i] = 0.49
    boxes[i+3] = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
    boxes[i+3][i+3] = -0.49
end
boxes[7] = {-0.49, -0.49, -0.49, 0.49, 0.49, 0.49}

-- Determines whether a node def has a regular collision box
local function regular_collision_box(def)
    local box = def.collision_box or def.node_box
    if not box then
        return true
    end
    if box.type == "regular" then
        return true
    end
    local fixed = box.fixed
    if box.type == "fixed" and fixed[1] == -0.5 and fixed[2] == -0.5 and fixed[3] == -0.5
            and fixed[4] == 0.5 and fixed[5] == 0.5 and fixed[6] == 0.5 then
        return true
    end
    return false
end

-- Replace regular collision boxes in definitions with the created boxes
local registered_nodes = minetest.registered_nodes
local original_nodes = {}
local function add_original_node(name, def)
    original_nodes[name] = setmetatable({
        collision_box = {type = "regular"}
    }, {__index = def})
end
do
    -- Override already registered nodes
    for name, def in pairs(registered_nodes) do
        if regular_collision_box(def) then
            add_original_node(name, def)
            minetest.override_item(name, {
                collision_box = collisionbox
            })

        end
    end
    -- Fix nodes registered after this mod is loaded on registration
    local register_node = minetest.register_node
    -- TODO override register_item too
    function minetest.register_node(name, def)
        if regular_collision_box(def) then
            add_original_node(name, def)
            def.collision_box = collisionbox
        end
        register_node(name, def)
    end
end

-- Item entity must be provided with our copy of the registered nodes table, which provides regular collision box definitions
local def = minetest.registered_entities["__builtin:item"]
local on_step = def.on_step
function def.on_step(...)
    -- HACK temporarily replace the registered_nodes table
    minetest.registered_nodes = original_nodes
    on_step(...)
    minetest.registered_nodes = registered_nodes
end
minetest.register_entity(":__builtin:item", def)