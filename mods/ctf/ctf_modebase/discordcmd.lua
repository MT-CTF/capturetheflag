minetest.register_chatcommand("discord", {
    params = "",
    description = "Join our Discord server!",
    func = function(name, param)
        local discord_link = "https://discord.gg/gwrmgr4nfY"
        local formspec = "size[8,5]" ..
                         "label[1,1;Discord Of Capture The Flag:]" ..
                         "field[1,2.5;6,1;discord_link;Discord link:;" .. discord_link .. "]" ..
                         "button_exit[2,4;4,1;close;Close]"
        minetest.show_formspec(name, "discord_form", formspec)
    end,
})
