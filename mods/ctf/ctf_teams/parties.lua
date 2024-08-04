ctf_teams.parties = {}
ctf_teams.invites = {}
-- If this is not set it will still block parties bigger than the team size of the round
ctf_teams.MAX_PARTY_SIZE = 4

local partiescmdbuilder = chatcmdbuilder.register("party", {
	description = "Party management commands",
	params = "invite <player> | accept <player> | leave | info"
})

partiescmdbuilder:sub("info", function (name)
    local playerPartyInfo = ctf_teams.getPlayerPartyInfo(name)
    if playerPartyInfo == nil then
        minetest.chat_send_player(name, "You are not in a party")
    else
        local partyMembersString = "Party members: "
        for index, playerName in ipairs(playerPartyInfo.player_party) do
            partyMembersString = partyMembersString..playerName.." "
        end
        minetest.chat_send_player(name, partyMembersString)
    end

    local playerInviteInfo = ctf_teams.getPlayerInviteInfo(name)
    if playerInviteInfo == nil then
        minetest.chat_send_player(name, "You have no outgoing or incoming invites")
        return
    end
    if playerInviteInfo.outgoingInvites == nil then
        minetest.chat_send_player(name, "You have no outgoing invites")
    else
        local outgoingInvitesString = "You have pending outgoing invites to: "
        for key, invite in pairs(playerInviteInfo.outgoingInvites) do
            outgoingInvitesString = outgoingInvitesString..invite.invited.." "
        end
        minetest.chat_send_player(name, outgoingInvitesString)
    end

    if playerInviteInfo.incomingInvites == nil then
        minetest.chat_send_player(name, "You have no incoming invites")
    else
        local incomingInvitesString = "You have pending incoming invites from: "
        for key, invite in pairs(playerInviteInfo.incomingInvites) do
            incomingInvitesString = incomingInvitesString..invite.inviter.." "
        end
        minetest.chat_send_player(name, incomingInvitesString)
    end
end)

partiescmdbuilder:sub("invite :player:username", function (name, player)
	if minetest.get_player_by_name(player) then
        if player == name then
            minetest.chat_send_player(name, "You can't invite yourself to a party, silly!")
            return
        end
        local inviteInfo = ctf_teams.getPlayerInviteInfo(name)
        if inviteInfo then
            for index, invite in ipairs(inviteInfo.outgoingInvites) do
                if invite.invited == player then
                    minetest.chat_send_player(name, "You already invited "..player.." to your party.")
                    return
                end
            end
        end
        local partyInfo = ctf_teams.getPlayerPartyInfo(name)
        if partyInfo then
            for index, playerName in ipairs(partyInfo.player_party) do
                if playerName == player then
                    minetest.chat_send_player(name, player.." is already in your party.")
                    return
                end
            end
        end
        local response = ctf_teams.canPartyAcceptNewPlayers(name)
        if response ~= "no" then
            minetest.chat_send_player(name, "Could not invite "..player.." to your party.")
            if (response == "over max party size") then
                minetest.chat_send_player(name, "Your party is already at the max size of "..ctf_teams.MAX_PARTY_SIZE)
            elseif (response == "over team size") then
                minetest.chat_send_player(name, "Your party is already at the team size, adding more players would make it unfair.")
            end
            return
        end
		minetest.chat_send_player(name, "Inviting "..player.." to your party. They must accept to join.")
        minetest.chat_send_player(player, name.." has invited you to their party. Type \"/party accept "..name.."\" to join.")
        table.insert(ctf_teams.invites, {inviter = name, invited = player})
	else
		minetest.chat_send_player(name, player.." is not online, or isn't a player")
	end
end)
partiescmdbuilder:sub("accept :player:username", function (name, player)
    if minetest.get_player_by_name(player) == nil then
        minetest.chat_send_player(name, player.." is not online, or isn't a player")
        return
    else if ctf_teams.getPlayerPartyInfo(name) ~= nil then
        minetest.chat_send_player(name, "You are currently in a party. You must leave using \"/party leave\" before you can accept new invitations.")
        return
    end
    local response = ctf_teams.canPartyAcceptNewPlayers(player)
        if response ~= "no" then
            minetest.chat_send_player(name, "Could not accept party invite from "..player)
            if (response == "over max party size") then
                minetest.chat_send_player(name, player.."'s party is already at the max size of "..ctf_teams.MAX_PARTY_SIZE)
            elseif (response == "over team size") then
                minetest.chat_send_player(name, player.."'s party is already at the team size, adding more players would make it unfair.")
            end
            return
        end

    for index, invite in ipairs(ctf_teams.invites) do
        if invite.inviter == player and invite.invited == name then
            -- Create a new party if the inviter is currently not in one
            local inviterPartyInfo = ctf_teams.getPlayerPartyInfo(player)
            if inviterPartyInfo == nil then
                table.insert(ctf_teams.parties, {player, name})
                minetest.chat_send_player(name, "You have joined "..player.."'s party. This will take effect next match.")
                minetest.chat_send_player(player, name.." has joined your party. This will take effect next match.")
            else
                for index, player_name in ipairs(inviterPartyInfo.player_party) do
                    minetest.chat_send_player(player_name, name.." has joined your party. This will take effect next match")
                end
                minetest.chat_send_player(name, "You have joined "..player.."'s party. This will take effect next match.")
                table.insert(inviterPartyInfo.player_party, name)
            end
            local inviteIndexToDelete = nil
            for index, invite in ipairs(ctf_teams.invites) do
                if invite.inviter == player and invite.invited == name then
                    inviteIndexToDelete = index
                    break
                end
            end
            if inviteIndexToDelete ~= nil then
                table.remove(ctf_teams.invites, inviteIndexToDelete)
            end
            return
        end
    end
    minetest.chat_send_player(name, "You currently have no party invites from "..player)
end
end)
partiescmdbuilder:sub("leave", function (name)
    local playerPartyInfo = ctf_teams.getPlayerPartyInfo(name)
    if playerPartyInfo ~= nil then
        for index, player_name in ipairs(ctf_teams.parties[playerPartyInfo.party_index]) do
            if name ~= player_name then
                minetest.chat_send_player(player_name, name.." has left your party.")
            end
        end
        ctf_teams.removeFromParty(playerPartyInfo)
        minetest.chat_send_player(name, "You have left the party")
    else
        minetest.chat_send_player(name, "You are not in a party")
    end
end)
--- @param player string
ctf_teams.getPlayerPartyInfo = function (player)
    if minetest.get_player_by_name(player) == nil then
        return nil
    else
        for party_index, party in ipairs(ctf_teams.parties) do
            for player_index, party_player in ipairs(party) do
                if party_player == player then
                    return {
                        player_party = party,
                        player_index = player_index,
                        party_index = party_index
                    }
                end
            end
        end
        return nil
    end
end
-- Can pass either a player name or party info
--- @param arg string | table
ctf_teams.removeFromParty = function (arg)
    local playerPartyInfo = nil
    if type(arg) == "string" then
        playerPartyInfo = ctf_teams.getPlayerPartyInfo(arg)
    elseif type(arg) == "table" then
        playerPartyInfo = arg
    end
    if playerPartyInfo ~= nil then
        table.remove(playerPartyInfo.player_party, playerPartyInfo.player_index)
        local playerPartyLength = #playerPartyInfo.player_party
        if playerPartyLength < 2 then
            if playerPartyLength == 1 then
                for index, player_name in ipairs(playerPartyInfo.player_party) do
                    minetest.chat_send_player(player_name, "Your party has disbanded because you were the only one left")
                end
            end
            table.remove(ctf_teams.parties, playerPartyInfo.party_index)
        end
    end
end
--- @param player string
ctf_teams.getPlayerInviteInfo = function (player)
    if minetest.get_player_by_name(player) == nil then
        return nil
    else
        local infoToReturn = {outgoingInvites = nil, incomingInvites = nil}
        for invite_index, invite in ipairs(ctf_teams.invites) do
            if invite.inviter == player then
                if infoToReturn.outgoingInvites == nil then
                    infoToReturn.outgoingInvites = {}
                end
                table.insert(infoToReturn.outgoingInvites, invite)
            end
        end
        for invite_index, invite in ipairs(ctf_teams.invites) do
            if invite.invited == player then
                if infoToReturn.incomingInvites == nil then
                    infoToReturn.incomingInvites = {}
                end
                table.insert(infoToReturn.incomingInvites, invite)
            end
        end
        if (infoToReturn.outgoingInvites ~= nil) or (infoToReturn.incomingInvites ~= nil) then
            return infoToReturn
        else
            return nil
        end
    end
end
--- @param player string
ctf_teams.deleteAllInvitesInvolvingPlayer = function (player)
    local removedAllInvites = false
    while removedAllInvites == false do
        local hasRemovedInviteThisItteration = false
        for index, invite in ipairs(ctf_teams.invites) do
            if (invite.inviter == player) or (invite.invited == player) then
                table.remove(ctf_teams.invites, index)
                hasRemovedInviteThisItteration = true
                break
            end
        end
        if hasRemovedInviteThisItteration == false then
            removedAllInvites = true
        end
    end
end

-- Remove the player from their party if they were in one, and clear all invites involving them
ctf_teams.checkAndClearAllPartyInfo = function (player)
    local playerPartyInfo = ctf_teams.getPlayerPartyInfo(player)
    if playerPartyInfo ~= nil then
        ctf_teams.removeFromParty(playerPartyInfo)
    end
    local playerInviteInfo = ctf_teams.getPlayerInviteInfo(player)
    if playerInviteInfo ~= nil then
        ctf_teams.deleteAllInvitesInvolvingPlayer(player)
    end
end

---@param player string
---@return "no" | "over max party size" | "over team size"
-- Lets you know if a party can accept new players or not. Is not used by deleteOversizedParties which is run on round start.
function ctf_teams.canPartyAcceptNewPlayers(player)
    local player_party_info = ctf_teams.getPlayerPartyInfo(player)
    -- Assumes it is a two team map next so you can invite a larger number of players to your party even if you are currently on a 4 team map,
    -- but it still may disband the party next round if it too big for the map.
    local playersPerTeam =  math.floor(#minetest.get_connected_players() / 2)

    if (playersPerTeam == 1) or (playersPerTeam == 0) then
        return "over team size"
    end
    if player_party_info ~= nil then
        if (#player_party_info.player_party >= playersPerTeam) then
            return "over team size"
        elseif #player_party_info.player_party >= ctf_teams.MAX_PARTY_SIZE then
            return "over max party size"
        end
        return "no"
    end
    return "no"
end

-- Deletes any parties that are larger than the MAX_PARTY_SIZE or larger than the team size of that round
function ctf_teams.deleteOversizedParties()
    local removedAllOversizedParties = false
    while removedAllOversizedParties == false do
        local hasRemovedInviteThisItteration = false
        for index, party in ipairs(ctf_teams.parties) do
            if #party > ctf_teams.MAX_PARTY_SIZE then
                for _, player in pairs(party) do
                    minetest.chat_send_player(player, "Your party ("..#party.." players) has been disbanded because it is over the max party size of "..ctf_teams.MAX_PARTY_SIZE)
                end
                table.remove(ctf_teams.parties, index)
                hasRemovedInviteThisItteration = true
                break
            end
            local teamSize = math.floor(#minetest.get_connected_players() / #ctf_teams.current_team_list)
            if #party > teamSize then
                for _, player in pairs(party) do
                    minetest.chat_send_player(player, "Your party ("..#party.." players) has been disbanded because it is bigger than the team size of "..teamSize.." players.")
                end
                table.remove(ctf_teams.parties, index)
                hasRemovedInviteThisItteration = true
                break
            end
        end
        if hasRemovedInviteThisItteration == false then
            removedAllOversizedParties = true
        end
    end
end
-- This puts all party players onto their teams, and returns a table of all the non-party players
function ctf_teams.allocate_parties(unallocatedPlayers)
	local nonPartyPlayers = unallocatedPlayers
	local partiesToAllocate = {}
	for _, party in pairs(ctf_teams.parties) do
		table.insert(partiesToAllocate, party)
	end
	-- Make partiesToAllocate be in order of largest party to smallest
	table.sort(partiesToAllocate, function (a, b)
		return #a > #b
	end)
	for _, party in ipairs(partiesToAllocate) do
		local weakestTeam = ctf_teams.getTeamToAllocatePartyTo()
		for _, player in pairs(party) do
			ctf_teams.set(player, weakestTeam, true)
			
			for index, playerToCheck in pairs(nonPartyPlayers) do
				local nameToCheck = PlayerName(playerToCheck)
				if nameToCheck == player then
					print("removing a party player from allocator pool")
					table.remove(nonPartyPlayers, index)
					break
				end
			end
		end
	end
	return nonPartyPlayers
end

-- This is run to find which team a party should be added to.
function ctf_teams.getTeamToAllocatePartyTo()
    -- A lot of this is adapted from team_allocator in features.lua
    local team_scores = ctf_modebase:get_current_mode().recent_rankings.teams()

    local best_kd = nil
    local worst_kd = nil
    local best_players = nil
    local worst_players = nil
    local total_players = 0

    for _, team in ipairs(ctf_teams.current_team_list) do
        local players_count = ctf_teams.online_players[team].count
        local players = ctf_teams.online_players[team].players

        local bk = 0
        local bd = 1

        for name in pairs(players) do
            local rank = ctf_modebase:get_current_mode().rankings:get(name)

            if rank then
                if bk <= (rank.kills or 0) then
                    bk = rank.kills or 0
                    bd = rank.deaths or 0
                end
            end
        end

        total_players = total_players + players_count

        local kd = bk / bd
        local match_kd = 0
        local tk = 0
        if team_scores[team] then
            if (team_scores[team].score or 0) >= 50 then
                tk = team_scores[team].kills or 0

                kd = math.max(kd, (team_scores[team].kills or bk) / (team_scores[team].deaths or bd))
            end

            match_kd = (team_scores[team].kills or 0) / (team_scores[team].deaths or 1)
        end

        if not best_kd or match_kd > best_kd.a then
            best_kd = {s = kd, a = match_kd, t = team, kills = tk}
        end

        if not worst_kd or match_kd < worst_kd.a then
            worst_kd = {s = kd, a = match_kd, t = team, kills = tk}
        end

        if not best_players or players_count > best_players.s then
            best_players = {s = players_count, t = team}
        end

        if not worst_players or players_count < worst_players.s then
            worst_players = {s = players_count, t = team}
        end
    end

    if worst_players.s == 0 then
        return worst_players.t
    end

    local kd_diff = best_kd.s - worst_kd.s
    local actual_kd_diff = best_kd.a - worst_kd.a
    local players_diff = best_players.s - worst_players.s

    if kd_diff > 0.4 then
        return worst_kd.t
    else
        return worst_players.t
    end
    
end