local npcManager = require("npcManager")
local AI = require("AI/fireServer")

local sampleNPC = {}
local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,
	gfxheight = 56,
	gfxwidth = 40,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	width = 36,
	height = 56,

	frames = 2,
	framestyle = 1,
	framespeed = 8,
	speed = 0,

	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,

	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside = false,
	grabtop = false,
	ishot = true,
	ignorethrownnpcs = true,
	staticdirection = true,
	luahandlesspeed = true,

	-- custom settings
	waitTime = 16,
	thrownSize = vector(32, 32),
	rotationMultiplier = 2,
	
	explosionRadius = 48,
	deathEffect = npcID - 3,

	minHeight = 128,  -- minimum height the npc must reach
	maxHeight = 640, -- maximum height the npc could reach

	minDistanceX = 128, -- minimum distance between the npc and the player
	maxDistanceX = 640, -- maximum distance the npc can reach

	bounceSFX = {id = "AI/fireServer-bounce.wav", volume = 1},
	explodeSFX = {id = "AI/fireServer-explosion.wav", volume = 1},
}

npcManager.setNpcSettings(sampleNPCSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_OFFSCREEN,
	}, 
	{
		[HARM_TYPE_PROJECTILE_USED]=nil,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=nil,
		[HARM_TYPE_OFFSCREEN]=10,
	}
);

AI.registerExplosive(npcID)

return sampleNPC