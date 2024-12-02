local override_item = core.override_item
local registered_nodes = table.copy(core.registered_nodes)
local relevant_nodes = {}


-- Determine all stairs and slabs by their respective groups and add them to
-- the table of nodes to handle.
for name,definition in pairs(registered_nodes) do
    local groups = definition.groups or {}
    local relevant = ((groups.stair == 1) or (groups.slab == 1))
    if relevant then
        table.insert(relevant_nodes, name)
    end
end


-- Iterate over all stairs and slabs and remove the not_in_creative_inventory
-- group to show them in the creative inventory again.
for _,name in pairs(relevant_nodes) do
    local groups = registered_nodes[name].groups
    groups.not_in_creative_inventory = nil
    override_item(name, { groups = groups })
end
