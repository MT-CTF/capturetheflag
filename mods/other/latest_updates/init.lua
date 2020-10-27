local latest_updates = minetest.formspec_escape([[
+ Made lava instantly heal players
+ Made bandages give 6 score when healing flag holder
+ Made grenades work like the old CTF grenades
+ Increased score medics get from using bandages
+ Gave medic bandages infinite uses
- Prevented knights from using the SMG
- Gave medic class building tools and prevented them from using SMG/Shotgun
- Changed fall damage to use the combat system
- Increased damage dealt by knights (up to +1.5 hp depending on time since last punch) when wielding swords
- Merged the sniper class with the shooter class
- Changed bandages to give two points per heal
- Made rifle automatic and doubled damage
- Added combat mode
- Added Sticky grenades
- Added automatic skip votes
]])

if minetest.global_exists("sfinv") then
	sfinv.register_page("latest_updates:latest_updates", {
		title = "Updates",
		get = function(self, player, context)
			return sfinv.make_formspec(player, context,
				"real_coordinates[true]" ..
				"label[3,0.4;"..minetest.colorize("#00aa00", "The latest updates to CTF are listed here").."]" ..
				"box[0.1,0.65;10.4,10.1;#222222]" ..
				"textarea[0.1,0.65;10.4,10.1;;;" .. latest_updates .. "]", false)
		end
	})
end
