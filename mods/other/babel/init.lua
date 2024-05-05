-- SPDX-License-Identifier: LGPL-3.0-only
-- Copyright (c) 2023 Marko Petrović, Nanowolf4
babel = {}
local storage = minetest.get_mod_storage()

local function getplayerlanguage(player)
	local lang = storage:get_string("lang:"..player)
	if not lang or lang == "" then
		return "en"
	end
	return lang
end
-- Preferred language was previously stored in player metadata. Switch to mod storage.
local function getplayerlanguage_playermeta(player)
	return minetest.get_player_by_name(player) and (minetest.get_player_by_name(player):get_meta():get("lang") or "en")
end
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local language = getplayerlanguage_playermeta(name)
	if language ~= "en" then
		storage:set_string("lang:"..name, language)
		-- Delete the key from player meta
		player:get_meta():set_string("lang", "")
	end
end)

minetest.register_privilege("babelmoderator")

dofile(minetest.get_modpath("babel").."/google_engine.lua")

local httpapitable = minetest.request_http_api() or error("babel: http api required!")

babel.register_http(httpapitable)

babel.sanitize = function(stringdata)
	stringdata = stringdata:gsub("&", "%%26")
	stringdata = stringdata:gsub("#","%%23")

	return stringdata
end

function babel.validate_lang(self, langstring)
	for target, _ in pairs(babel.langcodes) do
		if target == langstring then
			return true
		end
	end
	return false
end

local chat_history = {}

local function components(mystring)
	local iter = mystring:gmatch("%S+")
	local first = iter()
	if not first then
		return nil
	end
	if not iter() then
		return first, nil
	end

	local second = mystring:gsub("^"..first.." ", "", 1)
	return first, second
end


local function dotranslate(lang, phrase, handler)
	return babel:translateGoogle(minetest.strip_colors(phrase), lang, handler)
end

local charTable = {
    ["а"] = "a", ["б"] = "b", ["в"] = "v", ["г"] = "g", ["д"] = "d", ["е"] = "e", ["з"] = "z",
    ["и"] = "i", ["ј"] = "j", ["к"] = "k", ["л"] = "l", ["м"] = "m", ["н"] = "n", ["о"] = "o",
    ["п"] = "p", ["р"] = "r", ["с"] = "s", ["т"] = "t", ["у"] = "u", ["ф"] = "f", ["х"] = "h", ["ц"] = "c"
}

local function cyrillicToLatin(input)
	return utf8_simple.replace(input, charTable)
end

minetest.register_on_chat_message(function(player, message)
	if minetest.player_exists(player) and not minetest.check_player_privs(player, {shout = true}) then
		return
	end

	local targetlang

	-- Search for %* token at the end
	for token in message:gmatch("[^%%]+") do
		targetlang = utf8_simple.sub(token, 1, 2)
		-- No percent sign in the message -> token = message
		if token == message then
			targetlang = nil
		end
	end

	if not targetlang then
		return false
	end

	-- Remove targetlang token from the end of the message
	message = utf8_simple.reverse(message)
	local reversedLangCode = utf8_simple.reverse(targetlang)
	-- Escaping special characters in targetlang before using it in pattern matching
	reversedLangCode = reversedLangCode:gsub("[%p%c]", "%%%1")

	message = message:gsub(reversedLangCode.."%%",'',1)
	message = utf8_simple.reverse(message)
	targetlang = cyrillicToLatin(targetlang)

	-- True, or error string
	local validation = babel:validate_lang(targetlang)

	if validation ~= true then
		minetest.chat_send_player(player, "Bad language code!")
	else
		dotranslate(targetlang, message, function(newphrase)
			minetest.chat_send_all("[Translated "..player.."]: "..newphrase)
		end)
	end
end)

minetest.register_chatcommand("b", {
	description = "Translate a player's last chat message. Use /lang to set your language",
	params = "<playername>",
	func = function (player, argstring)
		argstring = argstring or ""
		local args = argstring:split(" ")

		local targetplayer = args[1]

		if not targetplayer then
			minetest.chat_send_player(player, "Missing player name!")
			return
		end

		local targetlang = args[2]

		if not targetlang then
			targetlang = getplayerlanguage(player)
		end
		targetlang = cyrillicToLatin(targetlang)

		local validation = babel:validate_lang(targetlang)
		if validation ~= true then
			minetest.chat_send_player(player, "Bad language: " .. (targetlang or "(Not set!)"))
			return
		end

		if not chat_history[targetplayer] then
			minetest.chat_send_player(player, targetplayer.." has not said anything")
			return
		end

		dotranslate(targetlang, chat_history[targetplayer], function(newphrase)
			minetest.chat_send_player(player, "[Translated]: "..newphrase)
		end)
	end
})

minetest.register_chatcommand("bmsg", {
	description = "Send a private message to a player, in their preferred language",
	params = "<player> <sentence>",
	privs = {shout = true},
	func = function(player, argstring)
		local targetplayer, targetphrase = components(argstring)
		if not targetplayer then
			minetest.chat_send_player(player, "You have to provide player name!")
			return
		end
		if not targetphrase then
			minetest.chat_send_player(player, "Write the message you wish to send!")
			return
		end

		local targetlang = getplayerlanguage(targetplayer)
		targetlang = cyrillicToLatin(targetlang)

		if not babel:validate_lang(targetlang) then
			minetest.chat_send_player(player, "Bad target language")
			return
		end

		if not minetest.get_player_by_name(targetplayer) then
			minetest.chat_send_player(player, targetplayer.." is not a connected player")
			return
		end

		dotranslate(targetlang, targetphrase, function(newphrase)
			minetest.chat_send_player(targetplayer, "PM from " .. player .. ": " .. targetphrase .. "\n" ..
			"[Translated PM from " .. player .. "]: " .. newphrase)
			minetest.chat_send_player(player, "PM to " .. targetplayer .. ": " .. targetphrase .. "\n" ..
			"[Translated PM to " .. targetplayer .. "]: " .. newphrase)
			minetest.log("action", player .. " PM to " .. targetplayer .. " [Translated]: " .. newphrase)
		end)
	end
})

minetest.register_chatcommand("bbcodes", {
	description = "List the available language codes",
	func = function(player,command)
		minetest.chat_send_player(player,dump(babel.langcodes))
	end
})

minetest.register_chatcommand("bbset", {
	description = "Set a player's preferred language",
	params = "<player> <langcode>",
	privs = {babelmoderator = true},
	func = function(player, message)
		local tplayer, langcode = components(message)
		if not tplayer then
			minetest.chat_send_player(player, "You have to provide player name!")
			return
		elseif not langcode then
			minetest.chat_send_player(player, "You have to provide language code!")
		end

		if not minetest.player_exists(tplayer) then
			minetest.chat_send_player(player, "Player doesn't exist!")
			return
		end

		if babel:validate_lang(cyrillicToLatin(langcode)) then
			storage:set_string("lang:"..tplayer, langcode)
			minetest.chat_send_player(player, tplayer .. " : " .. langcode )
		else
			minetest.chat_send_player(player, tplayer .. " : Invalid language code!" )
		end
	end,
})

minetest.register_chatcommand("lang", {
	description = "Set preferred language",
	params = "<langcode>",
	privs = {},
	func = function(name, param)
		param = param or ""
		if babel:validate_lang(cyrillicToLatin(param)) then
			storage:set_string("lang:"..name, param)
			minetest.chat_send_player(name, "Your preferred language is set to (" .. param .. ")" )
		else
			minetest.chat_send_player(name,"Incorrect usage or the lang code is wrong. Example: (/lang en)" )
		end
	end,
})
