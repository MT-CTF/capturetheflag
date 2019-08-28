-- This mod is used to protect nodes in the capture the flag game
ctf.register_on_init(function()
	ctf.log("chat", "Initialising...")

	-- Settings: Chat
	ctf._set("node_ownership",          true)
end)

local old_is_protected = minetest.is_protected

function minetest.is_protected(pos, name)
	if not ctf.setting("node_ownership") then
		return old_is_protected(pos, name)
	end

	local team = ctf.get_territory_owner(pos)

	if not team or not ctf.team(team) then
		return old_is_protected(pos, name)
	end

	if ctf.player(name).team == team then
		return old_is_protected(pos, name)
	else
		minetest.chat_send_player(name, "You cannot dig on team "..team.."'s land")
		return true
	end
end
