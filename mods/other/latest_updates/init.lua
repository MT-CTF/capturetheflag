local latest_updates = minetest.formspec_escape([[
[!] Gave medics a paxel with the ability to take down pillars
+ Changed build time to 3 minutes
+ Added darkness_nerf until MTE fixes their lighting
+ Gave shooter class 2 ammo packs
+ Slightly buffed shooter class and knight melee dmg
+ Added mod `real_suffocation` with custom tweaks for CTF
+ Prevented medics from healing players damaged by drowning/lava
* Made bandages give 6 score when healing flag holder
* Made grenades work like the old CTF grenades
* Increased score medics get from using bandages
* Prevented knights from using the SMG
* Gave medic class building tools and prevented them from using SMG/Shotgun
* Increased damage dealt by knights (up to +1.5 hp depending on time since last punch) when wielding swords
* Added combat mode
* Added automatic skip votes
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
