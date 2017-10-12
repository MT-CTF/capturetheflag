## Score

* +5 for picking up a flag.
* +20 for then capturing the flag.
* +X for killing someone, where X is:
	* +5 for every kill they've made since last death in this match.
	* `15 * kd` ratio, with variable cap based on player's score:
		* capped at X * 10 for < X * 100 player score
			(eg 10 for 100, 20 for 200, 40 for 400+).
		* capped to 40.
		* deaths > kills gives 0 score
	* Limited to 0 ≤ X ≤ 100
	* If they don't have a good weapon: half given score.
	  A good weapon is a non-default one which is not a pistol, stone sword, or crossbow.
