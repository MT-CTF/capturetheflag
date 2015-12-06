dofile(minetest.get_modpath("join_fs") .. "/api.lua")

-- Rules slide from agreerules

join_fs.register_slide({
	name = "rules",
	should_show = function(player)
		return not minetest.check_player_privs(player:get_player_name(), {interact=true})
	end,
	show = function(player)
		local msgs = {
			"Welcome to Capture the Flag!",
			"Developed, hosted, and moderated by rubenwardy.",
			"    tip: use /vote_next to skip to the next round",
			",By playing on this server you agree to these rules:",
			"1. Be nice. eg: No (excessive or bad) swearing",
			"2. No dating",
			"3. Don't be a cheater",
			"    (No hacked clients or griefing/sabotage of team)",
			"4. Don't impersonate other community members",
			"Failure to follow these rules may result in a kick or ban",
			"     (temp or permanent) depending on severity."}

		local fs = ""
		for _, line in pairs(msgs) do
			if fs ~= "" then
				fs = fs .. ","
			end
			fs = fs .. minetest.formspec_escape(line)
		end

		fs = "size[8,9] textlist[0.1,0.1;7.8,7;rules;" .. fs .. "]"
		fs = fs .. " button_exit[0.5,7;3.5,2;yes;" ..
			minetest.formspec_escape("Yes, let me play!") .. "]"
		fs = fs .. " button[4,7;3.5,2;no;" ..
			minetest.formspec_escape("No, get me out of here!") .. "]"
		minetest.show_formspec(player:get_player_name(), "join_fs:rules", fs)
	end
})

minetest.register_on_player_receive_fields(function(player, form, fields)
	if form == "join_fs:rules" then
		local name  = player:get_player_name()

		if fields.rules then
			return true
		elseif not fields.yes or fields.no then
			minetest.kick_player(name,
				"You need to agree to the rules to play on this server. " ..
				"Please rejoin and confirm another time.")
			return true
		end

		local privs = minetest.get_player_privs(name)
		privs.shout = true
		privs.interact = true

		minetest.set_player_privs(name, privs)
		minetest.chat_send_player(name, "Welcome "..name.."! You have now permission to play!")

		join_fs.confirm(name, "rules")
		join_fs.show_next_slide(player)
	end
end)

join_fs.register_slide({
	name = "blood",
	should_show = function(player)
		return true
	end,
	show = function(player)
		local fs = "size[8,1.75]label[0,0;Would you like to see blood splatters when using a gun?]"
		fs = fs .. " button_exit[0.5,0.5;3.5,2;yes;" ..
			minetest.formspec_escape("Yes: Enable blood") .. "]"
		fs = fs .. " button_exit[4,0.5;3.5,2;no;" ..
			minetest.formspec_escape("No: Disable blood") .. "]"
		minetest.show_formspec(player:get_player_name(), "join_fs:blood", fs)
	end
})

minetest.register_on_player_receive_fields(function(player, form, fields)
	if form == "join_fs:blood" then
		local name  = player:get_player_name()

		if fields.yes then
			shooter:enable_blood(name)
			minetest.chat_send_player(name, "You have choosen to see blood!")
		elseif fields.no then
			shooter:disable_blood(name)
			minetest.chat_send_player(name, "You will no longer see blood!")
		else
			minetest.chat_send_player(name, "You need to choose an option!")
			join_fs.show_next_slide(player)
			return true
		end

		join_fs.confirm(name, "blood")
		join_fs.show_next_slide(player)
	end
end)
