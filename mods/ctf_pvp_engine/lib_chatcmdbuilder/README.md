# ChatCmdBuilder

Easily create complex chat commands with no regex.  
Created by rubenwardy  
License: MIT

# Usage

## Registering Chat Commands

`ChatCmdBuilder.new(name, setup)` registers a new chat command called `name`.
Setup is called immediately after calling `new` to initialise subcommands.

You can set values in the chat command definition by using def:
`ChatCmdBuilder.new(name, setup, def)`.

Here is an example:

```Lua
ChatCmdBuilder.new("admin", function(cmd)
	cmd:sub("kill :target", function(name, target)
		local player = minetest.get_player_by_name(target)
		if player then
			player:set_hp(0)
			return true, "Killed " .. target
		else
			return false, "Unable to find " .. target
		end
	end)

	cmd:sub("move :target to :pos:pos", function(name, target, pos)
		local player = minetest.get_player_by_name(target)
		if player then
			player:setpos(pos)
			return true, "Moved " .. target .. " to " .. minetest.pos_to_string(pos)
		else
			return false, "Unable to find " .. target
		end
	end)
end, {
	description = "Admin tools",
	privs = {
		kick = true,
		ban = true
	}
})
```

A player could then do `/admin kill player1` to kill player1,
or `/admin move player1 to 0,0,0` to teleport a user.

## Introduction to Routing

A route is a string. Let's look at `move :target to :pos:pos`:

* `move` and `to` are constants. They need to be there in order to match.
* `:target` and `:pos:pos` are parameters. They're passed to the function.
* The second `pos` in `:pos:pos` after `:` is the param type. `:target` has an implicit
  type of `word`.

## Param Types

* `word` - default. Any string without spaces.
* `number` - Any number, including decimals
* `int` - Any integer, no decimals
* `text` - Any string
* `pos` - 1,2,3 or 1.1,2,3.4567 or (1,2,3) or 1.2, 2 ,3.2

## Build chat command function

If you don't want to register the chatcommand at this point, you can just generate
a function using `ChatCmdBuilder.build`.

For example, this is the full definition of ChatCmdBuilder.new:

```Lua
function ChatCmdBuilder.new(name, func, def)
	def = def or {}
	def.func = ChatCmdBuilder.build(name, func)
	minetest.register_chatcommand(name, def)
end
```

## Run tests

```Bash
sudo apt-get install luajit
luajit init.lua
```
