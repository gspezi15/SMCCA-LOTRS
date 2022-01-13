local npcManager = require("npcManager")
local spout = require("spout")

local waterspout = {}
local npcID = NPC_ID

local settings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 96,
	width = 96,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 4,
	framestyle = 0,
	framespeed = 8,
	speed = 1,
	npcblocktop = true,
	playerblocktop = true,
	nohurt=true,
	spinjumpsafe = false,
	
	lava=false, --If enabled, kills the player on contact
	forcerise=true, --If enabled, makes the player rise when underneath
	fall=false,
}

spout.register(settings)

return waterspout