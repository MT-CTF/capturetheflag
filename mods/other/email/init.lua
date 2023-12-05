email = {
	log = function(msg) end
}
local _loading = true
local send_as = {}
local forward_to = {}
local storage = minetest.get_mod_storage()
local S = minetest.get_translator(minetest.get_current_modname())

if minetest.global_exists("chatplus") then
	email.log = chatplus.log

	function chatplus.on_old_inbox(inbox)
		if _loading then
			return
		end

		email.inboxes = inbox
	end
end

function email.init()
	email.inboxes = {}
	email.load()
	_loading = false
	if minetest.global_exists("chatplus") and chatplus.old_inbox then
		chatplus.on_old_inbox(chatplus.old_inbox)
	end
end

function email.load()
	local file = io.open(minetest.get_worldpath() .. "/email.txt", "r")
	if file then
		local from_file = minetest.deserialize(file:read("*all"))
		file:close()
		if type(from_file) == "table" then
			if from_file.mod == "email" and tonumber(from_file.ver_min) <= 1 then
				email.inboxes = from_file.inboxes
			else
				error("[Email] Attempt to read incompatible email.txt file.")
			end
		end
	end

	local forward_to = storage:get_string("forward_to")
	local send_as = storage:get_string("send_as")

	if forward_to ~= "" then
		forward_to = minetest.parse_json(forward_to) or {}
	else
		forward_to = {}
	end

	if send_as ~= "" then
		send_as = minetest.parse_json(send_as) or {}
	else
		send_as = {}
	end
end

function email.save()
	local file = io.open(minetest.get_worldpath() .. "/email.txt", "w")
	if file then
		file:write(minetest.serialize({
			mod = "email", version = 1, ver_min = 1,
			inboxes = email.inboxes }))
		file:close()
	end
end
minetest.register_on_shutdown(email.save)

function email.get_inbox(name)
	return email.inboxes[name] or {}
end

function email.clear_inbox(name)
	email.inboxes[name] = nil
	email.save()
end

minetest.register_on_joinplayer(function(player)
	local inbox = email.get_inbox(player:get_player_name())
	if #inbox > 0 then
		minetest.after(10, function()
			minetest.chat_send_player(player:get_player_name(),
				minetest.colorize("#00FF00",
					S("(@1) You have mail! Type /inbox to recieve", #inbox)))
		end)
	end
end)

function email.get_formspec(name)
	local inbox = email.get_inbox(name)

	local function row(fs, c1, date, from, msg)
		date = minetest.formspec_escape(date)
		from = minetest.formspec_escape(from)
		msg = minetest.formspec_escape(msg)
		return fs .. ",#d0d0d0," .. table.concat({date, c1, from, msg}, ",")
	end

	local fs = ("vertlabel[0,0;%s]"):format(S("Your Inbox"))
	fs  = fs .. "tablecolumns[color;text;color;text;text]"
	fs  = fs .. "tableoptions[highlight=#ffffff33]"
	fs  = fs .. "table[0.5,0;11.25,7;inbox;"
	fs  = fs .. ("#ffffff,%s,,%s,%s"):format(S("Date"), S("From"), S("Message"))
	if #inbox == 0 then
		fs = row(fs, "#d0d0d0", "", ":)", S("Well done! Your inbox is empty!"))
	else
		for i = 1, #inbox do
			local color = "#ffffff"
			if minetest.check_player_privs(inbox[i].from, {kick = true, ban = true}) then
				color = "#FFD700"
			end
			local msg = inbox[i].msg
			fs = row(fs, color, inbox[i].date, inbox[i].from, msg:sub(1, 44))
			while #msg > 45 do
				msg = msg:sub(45, #msg)
				fs = row(fs, color, "", "", msg:sub(1, 44))
			end
		end
	end
	fs = fs .. "]"

	fs = fs .. ("button[0,7.25;2,1;clear;%s]"):format(S("Delete All"))
	--fs = fs .. "button[0,7.25;2,1;clear;Mark as read]"
	fs = fs .. ("button_exit[10.1,7.25;2,1;close;%s]"):format(S("Close"))
	fs = fs .. ("label[2,7.4;%s]"):format(S("Exit then type /mail username message to reply"))

	return fs
end

function email.show_inbox(name, text_mode, custom_gui)
	if text_mode then
		local inbox = email.get_inbox(name)
		if #inbox == 0 then
			return true, S("Your inbox is empty!")
		else
			minetest.chat_send_player(name, S("@1 items in your inbox:", #inbox))
			for i = 1, #inbox do
				local item = inbox[i]
				minetest.chat_send_player(name, i .. ") " ..item.date ..
					" <" .. item.from .. "> " .. item.msg)
			end
			return true, S("End of mail (@1 items)", #inbox)
		end
	else
		if custom_gui then
			local fs = "size[12,8]" .. email.get_formspec(name)
			minetest.show_formspec(name, "email:inbox", fs)
		else
			local player = minetest.get_player_by_name(name)

			sfinv.set_page(player, sfinv.get_page(player))
		end

		return true, S("Opened inbox!")
	end
end

if minetest.global_exists("sfinv") then
	sfinv.register_page("email:inbox", {
		title = S("Inbox"),
		get = function(self, player, context)
			local name = player:get_player_name()
			return sfinv.make_formspec(player, context, email.get_formspec(name), false, "size[12,8]")
		end
	})
end

minetest.register_on_player_receive_fields(function(player,formname,fields)
	if fields.clear then
		local name = player:get_player_name()
		email.clear_inbox(name)

		minetest.chat_send_player(name, S("Inbox cleared!"))
		email.show_inbox(name)
	end

	--[[if fields.mark_all_read then
		if player and player.inbox and #player.inbox > 0 then
			for i = 1, #player.inbox do
				player.inbox[i].read = true
			end
			minetest.chat_send_player(name, "Marked all as read!")
			email.show_inbox(name)
		end
	end]]--
end)

function email.send_mail(aname, ato, msg)
	local name = send_as[aname]  or aname
	local to   = forward_to[ato] or ato

	minetest.log("action", string.format("[EMAIL] from %s to %s: %s", name, to, msg))
	email.log(string.format("Email from %s to %s: %s", name, to, msg))
	if not minetest.player_exists(to) then
		return false, S("Player '@1' does not exist", to)
	end

	local mail = {
		date = os.date("%Y-%m-%d %H:%M:%S"),
		from = name,
		msg = msg}

	if email.inboxes[to] then
		table.insert(email.inboxes[to], mail)
	else
		email.inboxes[to] = { mail }
	end

	email.save()

	minetest.chat_send_player(to, minetest.colorize("#00FF00", "Mail from " .. minetest.colorize("#92C5FC", name) .. ": " .. msg))



	return true, S("Message sent to @1", ato)
end

minetest.register_chatcommand("inbox", {
	params = "[/clear/text]",
	description = S("Inbox: Blank to see inbox. Use 'clear' to empty inbox, 'text' for text only."),
	func = function(name, param)
		if param == "clear" then
			email.clear_inbox(name)

			return true, S("Inbox cleared")
		elseif param == "text" or param == "txt" or param == "t" or not minetest.get_player_by_name(name) then
			return email.show_inbox(name, true)
		else
			return email.show_inbox(name, false, true)
		end
	end
})

minetest.register_chatcommand("mail", {
	params = S("<playername> <some message>"),
	description = S("mail: add a message to a player's inbox"),
	func = function(name, param)
		local to, msg = string.match(param, "^([%a%d_-]+) (.+)")
		if to and msg then
			return email.send_mail(name, to, msg)
		else
			return false, S("Usage: mail <playername> <some message>")
		end

	end
})

dofile(minetest.get_modpath("email") .. "/hud.lua")

email.init()
