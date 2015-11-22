= Treasurer’s README file for Treasurer version 0.2.0 =
== Overview ==
* Name: Treasurer
* Technical name: `treasurer`
* Purpose: To provide an interface for mods which want to spawn ItemStacks randomly and an interface for mods which create new items.
* Version: 0.2.0
* Dependencies: none
* License: WTFPL

== Introduction ==
Problem:
There are a bunch of mods which have cool items but they won’t appear in the world by
themselves.
There are some mods which randomly distribute treasures into the world. Sadly, these only
distribute the items they know—which are just the items of the mod “default” most of the
time. The items of the other mods are completely missed.

The reason for this is that the distributing mods can’t know what sort of items are available
unless they explicitly depend on the mods that defines these. Viewed the other way round,
the item-defining mods that also distribute these items into the world are limited in the
sense that they only know one means of distributing items.

There is a gap between defining items and distributing them. Every time a mod does both,
flexibility is limited and expansion becomes difficult.

To bridge this gap, Treasurer has been written. Treasurer makes it possible a) for mods to define
treasures without bothering _how_ these are distributed into the world and b) for mods to distribute
treasures around the world without knowledge about _what_ treasures exactly are distributed.

== Technical side of Treasurer ==
=== technical overview ===
To get a working Treasurer architecture and actually get some treasures into the world,
you need:
* Treasurer
* at least one treasure registration mod
* at least one treasure spawning mod

=== treasurer registration mod ===
Firstly, there are the treasure registration mods (TRMs). The task of TRMs is to tell
Treasurer which items does it have to offer, which relative appearance probabilities these
treasures should have, how “precious” the treasure is considered (on a scale from 0 to 10)
, optionally how big the stack of items should be and optionally how much worn out it is.
TRMs must depend on at least two mods: On treasurer and on the mod or mods
where the items are defined. Technically, a TRM consists of nothing more than a long
list of “registration” function calls. While this seems trivial, the task of balancing
out probabilties and balancing out preciousness levels of treasures is not trivial
and it may take a long time to get right.

It is strongly recommended that a TRM really does nothing
more than registering treasures (and not defining items, for example). If you want
to make your mod compatible to Treasurer, don’t change your mod, write a TRM for
it instead.

There is an example TRM, called “`trm_default_example`”. It registers some items
of the default as treasures. Unsurprisingly, it depends on `treasurer` and `default`.

=== treasurer spawning mods ===
Secondly, there are the treasure spawning mods (TSMs). The task of a TSM is to somehow
distribute the available treasures into the world. This is also called “treasure
spawning”. How exactly the TSM spawns the treasures is completely up the TSM. But a
TSM has to request Treasurer to get some random treasures to distribute. A TSM may
optionally request to filter out treasures outside certain preciousness levels
and groups, so the result is a bit controllable and not completely random.
Treasurer can not guarantee to return the requestet amount of treasures, it may
return an empty table, for two reasons:

* There is no TRM activated. There must be at least one to work.
* The filters filtered out everything, leaving Treasurer with an empty treasure pool
to choose from. This problem can be fixed by installing more TRMs or by balancing the
existing TRMs to cover as many preciousness levels as possible. It also may be that
the range specified by the TSM was too small. It is recommended to keep the
requested range at least of a size of 1. Treasurer does, however, guarantee that
the returned treasures are always in the requested bounds.

A TSM has to at least depend on Treasurer.
Unlike for TRMs, it may not be a problem to also do some other stuff than just
spawning treasures if it seems feasible. You may choose to make your TSM fully 
dependant on Treasure, then it won’t work without Treasurer. You may also choose
to only add an optional dependency on Treasurer. For this to work, your mod must
now select its own treasures, which of course will only come from a rather limited
pool.

To check if the Treasurer mod is installed, you can use something like this in
your code:

```
if(minetest.get_modpath("treasurer")~=nil) then
	-- Treasurer is installed.
	-- You can call Treasurer’s functions here.
else
	-- Treasurer is not installed.
	-- You may write your replacement code here.
	-- You can not call Treasurer’s funcitons here.
end
```

There are two example TSMs. The first one is a very basic one and called “`tsm_gift_example`”.
It gives a “welcome gift” (1 random treasure) to players who just joined the server
or who respawn. The preciousness and group filters are not used. It does only depend on
Treasurer. The second one is called “`tsm_chests_example`” and pretty advanced for an example.
It places chests of the mod “default” between 20 and 200 node lenghts below the water
surface and puts 1-6 random treasures into these. The lower the chest, the higher
the preciousness. It depends on treasurer and default (for the chests, of course).

=== Recap ===
TRMs define treasures, TSMs spawn them. Treasurer manages the pool of available treasures.
TRMs and TSMs do not have to know anything from each other.
TRMs and TSMs do not neccessarily have to change any line of code of other mods to function.
Treasurer depends on nothing.

Important: It should always only be neccessary for TRMs and TSMs to depend on Treasurer.
All other mods do NOT HAVE TO and SHOULD NOT depend on Treasurer.



=== Treasure attributes ===
This section explains the various attributes a treasure can have.

==== Rarity ====
Rarity in Treasurer works in a pretty primitive way: The relative rarities of all
treasures from the treasure pool are simply all added up. The probabilitiy of one
certain treasure is then simply the rarity value divided by the sum.

==== Preciousness ====
How “precious” an item is, is highly subjective and also not always easy to categorize.
Preciousness in Treasurer’s terms should be therefore viewed as “utility” or as
“reward level” or “strength” or even “beauty” or whatever positive attributes you can
think of for items. See the text file `GROUPS_AND_PRECIOUSNESS` for a rough
guideline.
So, if you create a TRM and your treasure is something you want the player work
hard for, assign it a high preciousness. Everyday items that are already easy to
obtain in normal gameplay certainly deserve a lower precious than items that are
expensive to craft.
If your treasure consists of a powerful
item, assign it a high preciousness. When in doubt, try to value gameplay over
personal taste. Remember that TSMs can (and will!) filter out treasures based
on their preciousness.
For TSM authors, consider preciousness this way: If the trouble the player has
to get through to in order to obtain the treasure is high, better filter
out unprecious treasures. If your TSM distributes many treasures all over the world and these
are easy to obtain, filter out precious treasures.

TSMs also can just completely ignore preciousness, then the given treasures base
on sheer luck.

==== Treasurer groups ====
Every treasure can be assigned to a group. These groups are specific to Treasurer only.
The idea is that treasures which share a common property are member of the same group.
All groups have a name by which they are identified.
For example, if there are apples, plums, pears and oranges and those items can be
eaten for health, all those treasures would be members of the group “food”.

The group system can be used to further narrow down the treasure pool from which you
want Treasurer to return treasures. This makes it more interesting than just using
an one-dimensional preciousness scale.

Using the groups system is entirely optional. If your TRM does not specify any group,
your treasure will be assigned to the group “default”. It is not possible for a treasure
to not belong to any group. If your TSM does not specify a group parameter, Treasurer
will use all groups.
While not using groups as a TSM may be perfectly okay, not using groups as a TRM is
not recommended, because TSM which filter by groups may “overlook” your treasure,
even if it would actually fit, simply because you didn’t assign it to a specific group.

Note that Treasurer groups are completely distinct from Minetest’s group system.

You can basically invent your own groups on the fly, but it is strongly recommended that you
use the groups suggested in the text file `GROUPS_AND_PRECIOUSNESS` whenever possible, for
maximum portability of your TSM. The text file also has a rough guideline for finding
appropriate values for the preciousness.


==== Recap ====
Rarity determines the chance of a treasure, whereas preciousness determines
the difficulty to obtain it. Group

== Overview of examples ==
- `trm_default_example` - registers items of default mod
- `tsm_chests_example` - spawns chests (from the default mod)
- `tsm_gift_example` - gives one treasure as a “welcome gift” to joined or respawned players

== Treasurer API documentation ==
=== API documentation for treasure registration mods ===
The API consists of one function, which is called “`treasurer.register_treasure`”.

==== `treasurer.register_treasure` ====
Registers a new treasure (this means the treasure will be ready to be spawned by treasure spawning mods).

This function does some basic parameter checking to catch the most obvious
mistakes. If invalid parameters have been passed, the input is rejected and
the function returns false. However, it does not cover every possible
mistake, so some invalid treasures may slip through.
		
Rarity does not imply preciousness. A rare treasure may not neccessarily a
very precious one. A treasure chest with scorched stuff inside may be very
rare, but it’s certainly also very unprecious.

===== Parameters =====
* `name`: name of resulting `ItemStack`, e.g. “`mymod:item`”
* `rarity`: rarity of treasure on a scale from 0 to 1 (inclusive). lower = rarer
* `preciousness` : subjective preciousness on a scale from 0 to 10 (inclusive). higher = more precious.
* `count`: optional value which specifies the multiplicity of the item. Default is 1. See `count` syntax help in this file.
* `wear`: optional value which specifies the wear of the item. Default is 0, which disables the wear. See `wear` syntax help in this file.
* `treasurer_groups`: an optional table of group names to assign this treasure to. If omitted, the treasure is added to the default group.

===== Return value =====		
`true` on success, `false` on failure.

=== data formats ===
format of count type:
==== `count` ====
A `count` can be a number or a table 

* `number`: it’s always so many times
* `{min, max}`: it’s pseudorandomly between `min` and `max` times, `math.random` will be used to chose the value
* `{min, max, prob_func}`: it’s between `min` and `max` times, and the value is given by `prob_func` (see below)

==== `wear` ====
Completely analogous to `count`.

==== Format of `prob_func` function ====
There are no parameters.

It returns a random or pseudorandom number between 0 (inclusive) and 1 (exclusive).

`prob_func` is entirely optional, if it’s not used, treasurer will
default to using `math.random`. You can use `prob_func` to define your own
“randomness” function, in case you don’t wish your values to be evenly
distributed.

=== API documentation for treasure spawning mods ===
The API consists of one function, called “`treasurer.select_random_treasures`”.

==== `treasurer.select_random_treasures` ====
Request some treasures from treasurer.

===== Parameters =====
* `count`: (optional) amount of treasures. If this value is `nil`, Treasurer assumes a default of 1.
* `minimal_preciousness`: (optional) don’t consider treasures with a lower preciousness. If `nil`, there’s no lower bound.
* `maximum_preciousness`: (optional) don’t consider treasures with a higher preciousness. If `nil`, there’s no upper bound.
* `treasurer_group`: (optional): Only consider treasures which are members of at least one of the members of the provided Treasurer group table. `nil` = consider all groups
 

===== Return value =====
A table of `ItemStacks` (the requested treasures). It may be empty.

