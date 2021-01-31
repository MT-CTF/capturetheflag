local storage = minetest.get_mod_storage()
minetest.deserialize(storage:get_string("disallowed_names"))
disallowed_names=minetest.deserialize(storage:get_string("disallowed_names")) or {"sex","fuck","damn","drug","suicid"}

minetest.register_on_prejoinplayer(function(name)
    for k,v in pairs(disallowed_names) do
        if string.find(string.lower(name),string.lower(v)) then
            return "Your cannot use that username in this server. Please login with another username."
        end
    end
end)

--adds a name to disallowed names
minetest.register_chatcommand("bdname_add", {
    params = "<string>",
    privs = {ban = true},
    description = "Adds a name to the disallowed names list.",
    func = function(name,param)
        if param ~= "" then
            table.insert(disallowed_names,tostring(param))
            minetest.chat_send_player(name, "Added " .. param .. " to the list of banned words")
            local serial_table = minetest.serialize(disallowed_names)
            storage:set_string("disallowed_names", serial_table)
        else
            minetest.chat_send_player(name, "You need to add a name\n/bdname_add <name>")
        end
    end
})

--removes a name from disallowed names
minetest.register_chatcommand("bdname_remove",{
    description = "removes a name from disallowed names",
    params = "<name>",
    privs = {ban=true},
    func = function(name, param)
        if param ~="" then
            for k in pairs(disallowed_names) do
                if param == disallowed_names[k] then
                    table.remove(disallowed_names,k)
                end
            end
            storage:set_string("disallowed_names", minetest.serialize(disallowed_names))
        end
    end
})

-- List of disallowed names
minetest.register_chatcommand("bdname_list", {
    description = "lists all the disallowed",
    privs = {ban= true},
    func= function(name)
       for k in pairs(disallowed_names) do
            minetest.chat_send_player(name, disallowed_names[k])
       end
    end
})
