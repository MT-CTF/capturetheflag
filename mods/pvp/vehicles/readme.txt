How to drive/pilot/etc.:

Basic controls:
All vehicles are steered by looking around.
You can use the forward button(same as you would use for walking), to move the vehicles, but only some will be able to reverse. For example, cars can reverse but planes cannot.

Boosts:
Some vehicles can have a small boost when the 'use/aux1' key is held. It will only last for a limited time and it will not recharge whilst the key is still held down. 

Weapons:
Vehicles can also use weapons, for example the jet and tank, which will fire a missile when 'sneak' is pressed. They require a missile to be in the drivers inventory to do this. It is possible to have a second weapon, fired with 'use/aux1', but currently only the assault suit does this. It can use both bullets and missiles. The gun turret uses bullets.

Flight/Jumping/Hovering:
Some vehicles can fly, for example the jet. The jet will move upward when the driver looks up, or when the driver presses 'jump'. Using the jump key does not work very well at the moment. The plane is a bit differrent; It will hold it's height when 'jump' is pressed.
It is also possible for vehicles to jump or hover for a small amount of time. Currently only the Assault suit does this.

Boats and watercraft:
The speed boat can be used on water, but if it is driven onto land it will stop completely. If you are lucky you can move back into water, but be careful because this does not always work.

The Lightcycles:
The Lightcycles can place light barriers when 'sneak' is pressed. If the barrier from one type hits the other type, the vehicle will explode

Other things:
Vehicles will explode if they touch lava, so be careful.
Don't drive cars or planes etc. into water! they will sink.
If you do get a vehicle in a tricky spot, you can punch it whilst driving and it will be dropped.

The API:
vehicles.object_drive is the function used for the movement of vehicles.
It should be used in this format:
vehicles.object_drive(entity, dtime, {
})

In the above case, entity is used in place of an entity or object. If the function was to be used inside on_step for an entity, 'entity' would be replaced with 'self.object'
The table should contain the relevant variables listed below. The function is written so that these are all somewhat optional.

speed: This defines the speed of the vehicle, if unset it will be '10'

fixed: Setting this to 'true' will disable movement from the vehicle

decell: This defines the decelleration of the vehicle. The default is 0

shoots: If true then the vehicle can shoot with 'sneak'(arrow must be defined, default is false)

arrow: This should be the entity name for the weapon fired (default is nil) (requires an item with the name arrow_name.."_item" to be in the drivers inventory)

reload_time: how long it takes before the weapon can be fired again (default is 1)

shoot_y: y offset of the weapon, default is 1.5

shoot_angle: This will make the weapon shoot at a differrent vertical angle (default is 0)

infinite_arrow: if this is set then the vehicle won't need an arrow item to be in the inventory

arrow2/reload_time2/shoots2/shoot_y2/infinite_arrow2: same as above but fired with 'use/aux1'

jump: can be either 'hover' or 'jump' (default is nil). Hover lasts longer than jump.

fly: if true then the vehicle will fly (default is false)

fly_mode: can be either 'hold' or 'rise' (default is 'hold'). hold will keep the vehicle in place when 'jump' is pressed, and 'rise' will cause the vehicle to rise when the same key is pressed.

rise_speed: dependant on fly_mode being set to 'rise'. Defines the speed at which the vehicle will rise. (default is 0.1)

gravity: the gravity acting on the vehicle. This should be positive. (default is 1)

boost: if set to 'true' then the vehicle can boost with 'use/aux1' (default is false)

boost_duration: dependant on 'boost'. Determines how long a boost will last (default is 5).

boost_charge: dependant on 'boost'. Determines how long it takes before boost can be used again (default is 4)

boost_effect: particle texture that will fly out from behind the vehicle whilst boosting (default is nil)

hover_speed: the speed at which the vehicle will hover if 'jump' is set to 'hover' (default is 1.5)

jump_speed: the speed at which the vehicle will jump if 'jump' is set to 'jump' (default is 5)

simple_vehicle: removes all functionality except basic movement, use to reduce lag. (not implemented yet), default is false

is_watercraft: if set to true then the vehicle won't be stopped by water.
it will act like a boat unless swims is true. (default is false)

swims: will allow the vehicle to move underwater (not yet implemented) (default is false)

driving_sound: name of the sound file that will play when the vehicle is driving (default is nil)

sound_duration: !VERY IMPORTANT! if there is a driving sound then this should match it's duration. If this is not set then the sound could overlap and increase in volume (default is 5)

extra_yaw: use this if the model has incorrect rotation. It will rotate the model so it faces the right way whilst being driven (default is 0)

moving_anim/stand_anim/jump_anim/shoot_anim/shoot_anim2: animations for actions. Can be set individually. (default is nil)

place_node: name of the node that is placed by the vehicle (default is nil)

place_chance: nodes are placed when a random number between place_chance and 1 is equal to 1 (default is 1)

place_trigger: if true the vehicle will place the node defined by place_node when 'sneak' is pressed. (default is false)

death_node: name of the node that will make the vehicle explode, default is nil

destroy_node: name of the node that is destroyed if it toughes the vehicle, default is nil


