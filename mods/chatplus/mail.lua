-- Chat Plus
--    by rubenwardy
---------------------
-- mail.lua
-- Adds C+'s email.
---------------------

minetest.register_on_joinplayer(function(player)
	local _player = chatplus.poke(player:get_player_name(),player)
	-- inbox stuff!
	if _player.inbox and #_player.inbox>0 then
		minetest.after(10, minetest.chat_send_player,
			player:get_player_name(),
			"(" ..  #_player.inbox .. ") You have mail! Type /inbox to recieve")
	end
end)

-- inbox
function chatplus.showInbox(name, text_mode)
	-- Get player info
	local player = chatplus.players[name]

	-- Show
	if text_mode then
		if not player or not player.inbox or #player.inbox == 0 then
			return true, "Your inbox is empty!"
		else
			minetest.chat_send_player(name, #player.inbox .. " items in your inbox:")
			for i = 1, #player.inbox do
				local item = player.inbox[i]
				minetest.chat_send_player(name, i .. ") " ..item.date ..
					" <" .. item.from .. "> " .. item.msg)
			end
			return true, "End of mail (" .. #player.inbox .. " item)"
		end
	else
		local fs = "size[12,8]"
		fs  = fs .. "vertlabel[0,0;Chatplus Mail]"

		fs  = fs .. "tablecolumns[color;text;color;text;text]"
		fs  = fs .. "tableoptions[highlight=#ffffff33]"
		fs  = fs .. "table[0.5,0;11.25,7;inbox;"
		fs  = fs .. "#ffffff,Date,,From,Message"
		if not player or not player.inbox or #player.inbox == 0 then
			fs = fs .. ",#d0d0d0,,#d0d0d0," ..
				minetest.formspec_escape(":)") ..
				"," ..
				minetest.formspec_escape("Well done! Your inbox is empty!")
		else
			for i = 1, #player.inbox do
				fs = fs .. ",#D0D0D0,"
				fs = fs .. minetest.formspec_escape(player.inbox[i].date) .. ","
				if minetest.check_player_privs(player.inbox[i].from, {kick = true, ban = true}) then
					fs = fs .. "#FFD700,"
				else
					fs = fs .. "#ffffff,"
				end
				fs = fs .. minetest.formspec_escape(player.inbox[i].from) .. ","
				fs = fs .. minetest.formspec_escape(player.inbox[i].msg)
			end
		end
		fs = fs .. "]"

		fs = fs .. "button[0,7.25;2,1;clear;Delete All]"
		--fs = fs .. "button[0,7.25;2,1;clear;Mark as read]"
		fs = fs .. "button_exit[10.1,7.25;2,1;close;Close]"
		fs = fs .. "label[2,7.4;Exit then type /mail username message to reply]"

		minetest.show_formspec(name, "chatplus:inbox", fs)

		return true, "Opened inbox!"
	end

	return true
end

minetest.register_on_player_receive_fields(function(player,formname,fields)
	if fields.clear then
		local name = player:get_player_name()
		chatplus.poke(name).inbox = {}
		chatplus.save()
		minetest.chat_send_player(name, "Inbox cleared!")
		chatplus.showInbox(name)
	end

	--[[if fields.mark_all_read then
		if player and player.inbox and #player.inbox > 0 then
			for i = 1, #player.inbox do
				player.inbox[i].read = true
			end
			chatplus.save()
			minetest.chat_send_player(name, "Marked all as read!")
			chatplus.showInbox(name)
		end
	end]]--
end)

minetest.register_chatcommand("inbox", {
	params = "clear?",
	description = "inbox: print the items in your inbox",
	func = function(name, param)
		if param == "clear" then
			local player = chatplus.poke(name)
			player.inbox = {}
			chatplus.save()

			return true, "Inbox cleared"
		elseif param == "text" or param == "txt" or param == "t" then
			return chatplus.showInbox(name, true)
		else
			return chatplus.showInbox(name, false)
		end
	end
})

function chatplus.send_mail(name, to, msg)
	minetest.log("ChatplusMail - To: "..to..", From: "..name..", MSG: "..msg)
	chatplus.log("ChatplusMail - To: "..to..", From: "..name..", MSG: "..msg)
	if chatplus.players[to] then
		table.insert(chatplus.players[to].inbox, {
			date = os.date("%Y-%m-%d %H:%M:%S"),
			from = name,
			msg = msg})
		chatplus.save()

		minetest.chat_send_player(to, name .. " sent you mail! Type /inbox to see it.")

		return true, "Message sent to " .. to
	else
		return false, "Player '" .. to .. "' does not exist"
	end
end

minetest.register_chatcommand("mail", {
	params = "name msg",
	description = "mail: add a message to a player's inbox",
	func = function(name, param)
		chatplus.poke(name)
		local to, msg = string.match(param, "^([%a%d_-]+) (.+)")

		if not to or not msg then
			minetest.chat_send_player(name,"mail: <playername> <msg>",false)
			return
		end

		return chatplus.send_mail(name, to, msg)
	end
})

minetest.register_globalstep(function(dtime)
	chatplus.count = chatplus.count + dtime
	if chatplus.count > 5 then
		chatplus.count = 0
		-- loop through player list
		for key,value in pairs(chatplus.players) do
			if (
				chatplus.loggedin and
				chatplus.loggedin[key] and
				chatplus.loggedin[key].player and
				value and
				value.inbox and
				chatplus.loggedin[key].player.hud_add and
				chatplus.loggedin[key].lastcount ~= #value.inbox
			) then
				if chatplus.loggedin[key].msgicon then
					chatplus.loggedin[key].player:hud_remove(chatplus.loggedin[key].msgicon)
				end

				if chatplus.loggedin[key].msgicon2 then
					chatplus.loggedin[key].player:hud_remove(chatplus.loggedin[key].msgicon2)
				end

				if #value.inbox>0 then
					chatplus.loggedin[key].msgicon = chatplus.loggedin[key].player:hud_add({
						hud_elem_type = "image",
						name = "MailIcon",
						position = {x=0.52, y=0.52},
						text="chatplus_mail.png",
						scale = {x=1,y=1},
						alignment = {x=0.5, y=0.5},
					})
					chatplus.loggedin[key].msgicon2 = chatplus.loggedin[key].player:hud_add({
						hud_elem_type = "text",
						name = "MailText",
						position = {x=0.55, y=0.52},
						text=#value.inbox .. " /inbox",
						scale = {x=1,y=1},
						alignment = {x=0.5, y=0.5},
					})
				end
				chatplus.loggedin[key].lastcount = #value.inbox
			end
		end
	end
end)
