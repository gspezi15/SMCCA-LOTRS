--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

local wildpiranhaAI = require("wildpiranha_ai")

--Create the library table
local wildPiranha = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local wildPiranhaSettings = {
	id = npcID,
	gfxheight = 64,
	gfxwidth = 64,
	width = 48,
	height = 48,
	gfxoffsetx = -8,
	gfxoffsety = 8,
	frames = 4,
	framestyle = 1,
	framespeed = 8,
	speed = 1,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,
	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	jumphurt = true,
	spinjumpsafe = true,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,

	--NPC-Specific Property
	
	--Piranha Plant's Shared setting is in AI files
}

--Applies NPC settings
npcManager.setNpcSettings(wildPiranhaSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
wildpiranhaAI.registerCommonHarmTypes(npcID)

wildpiranhaAI.register(npcID, false,0,math.pi,npcID-1)

--Gotta return the library table!
return wildPiranha