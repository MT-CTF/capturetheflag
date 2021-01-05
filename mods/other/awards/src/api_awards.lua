-- Copyright (c) 2013-18 rubenwardy. MIT.

local S = awards.gettext

function awards.register_award(name, def)
	def.name = name

	-- Add Triggers
	if def.trigger and def.trigger.type then
		local tdef = awards.registered_triggers[def.trigger.type]
		assert(tdef, "Trigger not found: " .. def.trigger.type)
		tdef:on_register(def)
	end

	function def:can_unlock(data)
		if not self.requires then
			return true
		end

		for i=1, #self.requires do
			if not data.unlocked[self.requires[i]] then
				return false
			end
		end
		return true
	end

	-- Add Award
	awards.registered_awards[name] = def

	local tdef = awards.registered_awards[name]
	if def.description == nil and tdef.getDefaultDescription then
		def.description = tdef:getDefaultDescription()
	end
end


-- This function is called whenever a target condition is met.
-- It checks if a player already has that award, and if they do not,
-- it gives it to them
----------------------------------------------
--awards.unlock(name, award)
-- name - the name of the player
-- award - the name of the award to give
function awards.unlock(name, award)
	-- Ensure the player is online.
	if not minetest.get_player_by_name(name) then
		return
	end

	-- Access Player Data
	local data  = awards.player(name)
	local awdef = awards.registered_awards[award]
	assert(awdef, "Unable to unlock an award which doesn't exist!")

	if data.disabled or
			(data.unlocked[award] and data.unlocked[award] == award) then
		return
	end

	if not awdef:can_unlock(data) then
		minetest.log("warning", "can_unlock returned false in unlock of " ..
				award .. " for " .. name)
		return
	end

	-- Unlock Award
	minetest.log("action", name.." has unlocked award "..award)
	data.unlocked[award] = award
	awards.save()

	-- Give Prizes
	if awdef and awdef.prizes then
		for i = 1, #awdef.prizes do
			local itemstack = ItemStack(awdef.prizes[i])
			if not itemstack:is_empty() then
				local receiverref = minetest.get_player_by_name(name)
				if receiverref then
					receiverref:get_inventory():add_item("main", itemstack)
				end
			end
		end
	end

	-- Run callbacks
	if awdef.on_unlock and awdef.on_unlock(name, awdef) then
		return
	end
	for _, callback in pairs(awards.on_unlock) do
		if callback(name, awdef) then
			return
		end
	end

	-- Get Notification Settings
	local title = awdef.title or award
	local desc = awdef.description or ""
	local background = awdef.background or "awards_bg_default.png"
	local icon = (awdef.icon or "awards_unknown.png") .. "^[resize:32x32"
	local sound = awdef.sound
	if sound == nil then
		-- Explicit check for nil because sound could be `false` to disable it
		sound = {name="awards_got_generic", gain=0.25}
	end

	-- Do Notification
	if sound then
		-- Enforce sound delay to prevent sound spamming
		local lastsound = data.lastsound
		if lastsound == nil or os.difftime(os.time(), lastsound) >= 1 then
			minetest.sound_play(sound, {to_player=name})
			data.lastsound = os.time()
		end
	end

	if awards.show_mode == "chat" then
		local chat_announce
		if awdef.secret then
			chat_announce = S("Secret Award Unlocked: %s")
		else
			chat_announce = S("Award Unlocked: %s")
		end
		-- use the chat console to send it
		minetest.chat_send_player(name, string.format(chat_announce, title))
		if desc~="" then
			minetest.chat_send_player(name, desc)
		end
	else
		local player = minetest.get_player_by_name(name)
		local one = player:hud_add({
			hud_elem_type = "image",
			name = "award_bg",
			scale = {x = 2, y = 1},
			text = background,
			position = {x = 0.5, y = 0.05},
			offset = {x = 0, y = 138},
			alignment = {x = 0, y = -1}
		})
		local hud_announce
		if awdef.secret then
			hud_announce = S("Secret Award Unlocked!")
		else
			hud_announce = S("Award Unlocked!")
		end
		local two = player:hud_add({
			hud_elem_type = "text",
			name = "award_au",
			number = 0xFFFFFF,
			scale = {x = 100, y = 20},
			text = hud_announce,
			position = {x = 0.5, y = 0.05},
			offset = {x = 0, y = 45},
			alignment = {x = 0, y = -1}
		})
		local three = player:hud_add({
			hud_elem_type = "text",
			name = "award_title",
			number = 0xFFFFFF,
			scale = {x = 100, y = 20},
			text = title,
			position = {x = 0.5, y = 0.05},
			offset = {x = 0, y = 100},
			alignment = {x = 0, y = -1}
		})
		local four = player:hud_add({
			hud_elem_type = "image",
			name = "award_icon",
			scale = {x = 2, y = 2}, -- adjusted for 32x32 from x/y = 4
			text = icon,
			position = {x = 0.5, y = 0.05},
			offset = {x = -200.5, y = 126},
			alignment = {x = 0, y = -1}
		})
		minetest.after(4, function()
			local player2 = minetest.get_player_by_name(name)
			if player2 then
				player2:hud_remove(one)
				player2:hud_remove(two)
				player2:hud_remove(three)
				player2:hud_remove(four)
			end
		end)
	end
end
