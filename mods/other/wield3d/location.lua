--[[

MIT License

Copyright (c) 2019 stujones11, Stuart Jones

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]--

-- Wielded Item Location Overrides - [item_name] = {bone, position, rotation}

local bone = "Arm_Right"
local pos = {x=0, y=5.5, z=3}
local scale = {x=0.25, y=0.25}
local rx = -90
local rz = 90

wield3d.location = {
	["default:torch"] = {bone, pos, {x=rx, y=180, z=rz}, scale},
	["default:sapling"] = {bone, pos, {x=rx, y=180, z=rz}, scale},
	["flowers:dandelion_white"] = {bone, pos, {x=rx, y=180, z=rz}, scale},
	["flowers:dandelion_yellow"] = {bone, pos, {x=rx, y=180, z=rz}, scale},
	["flowers:geranium"] = {bone, pos, {x=rx, y=180, z=rz}, scale},
	["flowers:rose"] = {bone, pos, {x=rx, y=180, z=rz}, scale},
	["flowers:tulip"] = {bone, pos, {x=rx, y=180, z=rz}, scale},
	["flowers:viola"] = {bone, pos, {x=rx, y=180, z=rz}, scale},
	["default:shovel_wood"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["default:shovel_stone"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["default:shovel_steel"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["default:shovel_bronze"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["default:shovel_mese"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["default:shovel_diamond"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["bucket:bucket_empty"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["bucket:bucket_water"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["bucket:bucket_lava"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["screwdriver:screwdriver"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["screwdriver:screwdriver1"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["screwdriver:screwdriver2"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["screwdriver:screwdriver3"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["screwdriver:screwdriver4"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["vessels:glass_bottle"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["vessels:drinking_glass"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
	["vessels:steel_bottle"] = {bone, pos, {x=rx, y=135, z=rz}, scale},
}

