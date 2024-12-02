local _stack_max = tonumber(core.settings:get('redef_stack_max') or 100)
local all_objects = {}

-- Get the things that have to be altered.
for w,what in pairs({'items', 'nodes', 'craftitems', 'tools'}) do
    for name,definition in pairs(core['registered_'..what]) do
        if definition.stack_max == 99 then
            table.insert(all_objects, name)
        end
    end
end

-- Set stack size to the given value.
for _,name in pairs(all_objects) do
    core.override_item(name, {
        stack_max = _stack_max
    })
end

-- Set Luanti default values in case mods or something within the engine
-- will use them after the above code ran.
core.craftitemdef_default.stack_max = _stack_max
core.nodedef_default.stack_max = _stack_max
core.noneitemdef_default.stack_max = _stack_max
