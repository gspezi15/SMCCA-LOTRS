--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

local wildpiranhaAI = require("wildpiranha_ai")

--Create the library table
local wildPtooie = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local wildPtooieSettings = {
	id = npcID,
	gfxheight = 64,
	gfxwidth = 64,
	width = 48,
	height = 48,
	gfxoffsetx = -8,
	gfxoffsety = 8,
	frames = 8,
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
	--normalangle = 45, --Angle that the Needlenose would be shot out for the first 2 times in the cycle
	--specialangle = 80,	--Angle that the Needlenose would be shot out for the final time in the cycle
	splitsfx  = "piranha-plant-spit.ogg", -- Projectile Spit sfx, can be both filename and SMBX internal ID. Comment this to not play any sounds
	--projectileID = 755, --Projectile NPC ID, default is npcID+1. Uncomment this and change it manually otherwise.
	
	--Piranha Plant's Shared setting is in AI files
}

--Applies NPC settings
npcManager.setNpcSettings(wildPtooieSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
wildpiranhaAI.registerCommonHarmTypes(npcID)

wildpiranhaAI.register_Ptooie(npcID, false,NPC.config[npcID].projectileID or npcID+1,npcID-3)

--Gotta return the library table!
return wildPtooie