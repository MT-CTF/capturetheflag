# Vote
A mod for Minetest adding an API to allow voting on servers.

Version 0.1

Created by [rubenwardy](http://rubenwardy.com)  
Copyright (c) 2015, no rights reserved
Licensed under WTFPL or CC0 (you choose)

# Settings

* vote.maximum_active - maximum votes running at a time, votes are queued if it
                        reaches this. Defaults to 1.

# Example

```lua
minetest.register_chatcommand("vote_kick", {
	privs = {
		interact = true
	},
	func = function(name, param)
		if not minetest.get_player_by_name(param) then
			minetest.chat_send_player(name, "There is no player called '" ..
					param .. "'")
		end

		vote.new_vote(name, {
			description = "Kick player " .. param,
			help = "/yes,  /no  or  /abstain",
			name = param,
			duration = 60,

			on_result = function(self, result, results)
				if result == "yes" then
					minetest.chat_send_all("Vote passed, " ..
							#results.yes .. " to " .. #results.no .. ", " ..
							self.name .. " will be kicked.")
					minetest.kick_player(self.name, "The vote to kick you passed")
				else
					minetest.chat_send_all("Vote failed, " ..
							#results.yes .. " to " .. #results.no .. ", " ..
							self.name .. " remains ingame.")
				end
			end,

			on_vote = function(self, name, value)
				minetest.chat_send_all(name .. " voted " .. value .. " to '" ..
						self.description .. "'")
			end
		})
	end
})
```

# API

## Results

* voted - a key-value table. voted[name] = true if a player called name voted.
* abstain - a list of the names of players who abstained.
* <option> - a list of the names of players who voted for this option.

For example:

```lua
results = {
	voted = {
		one = true,
		two = true,
		three = true,
		four = true
	}
	yes = {"one", "three"},
	no = {"two"}
	abstain = {"four"}
}

```

## Values

* description - required.
* help - recommended. How to respond to the vote.
* duration - the duration of the vote, before it expires.
* perc_needed - if yes/no, this is the percentage needed to pass.
* options - a list of possible options. (not fully supported yet)

## Methods

* can_vote(self, name) - return true if player `name` can vote on this issue.
* on_start(self) - called when vote starts. Return false to cancel.
* on_decide(self, results) - see results section. Return the winning result.
* on_result(self, result, results) - when vote ends, result is the winning result
* on_vote(self, name, value) - called when a player casts a vote
* on_abstain(self, name) - called when a player abstains
