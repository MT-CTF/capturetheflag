# Data Formats

This file documents the contents of ctf.txt  
Values are added to the file using ctf.register_on_save and ctf.register_on_load.  
Here are the default values:

```lua
{
	players = ctf.players,
	teams = ctf.teams,
	diplo = ctf.diplo.diplo
}
```

## Players

Commonly called tplayer (may be called data or player in old code).  
Player name is commonly called name (but may be called other things in older code).

```lua
ctf.players = {
	username = (player_table)
}

(player_table) = {
	name = "username",
	team = "teamname",
	auth = false
	-- true if the player is a team admin. Team admins can change team settings.
	-- See ctf.can_mod()
	-- Note that priv:ctf_admin can also change team settings
}
```

## Teams

Commonly called team.  
Team name is commonly called tname (but may be called team in old code).

```lua
ctf.teams = {
	teamname = (team_table)
}

(team_table) = {
	data = {
		name = "teamname",
		color = "teamcolor" -- see ctf_colors
	},
	flags = {
		(flag_table), (flag_table)
	},
	players = {
		username1 = (player_table),
		username2 = (player_table)
	},
	spawn = { x=0, y=0, z=0 }
	-- fallback team spawn. Read by ctf.get_spawn() and overriding functions
	-- Don't use directly, instead call ctf.get_spawn("teamname")
}

(flag_table) = {
	x=0, y=0, z=0,
	flag_name = "Capital" -- human readable name
}
```

## Diplomacy

```lua
ctf.diplo.diplo = {
	(diplo_table), (diplo_table)
}

(diplo_table) = {
	one = "teamname1",
	two = "teamname2",
	state = "war" / "peace" / "alliance"
}
```
