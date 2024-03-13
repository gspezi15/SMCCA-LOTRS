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

	frames = 1,
	framestyle = 1,
	framespeed = 8,
	speed = 0,

	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,

	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside = false,
	grabtop = false,
	staticdirection = true,
	luahandlesspeed = true,

	transformID = npcID + 1,
	blackListedNPCs = table.map{}, -- add npc ids to this list that won't cause the tank to explode
	explosionRadius = 48,
	deathEffect = npcID - 2,

	hitSFX = {id = "AI/fireServer-hit.wav", volume = 1},
	explodeSFX = {id = "AI/fireServer-explosion.wav", volume = 1},
}

npcManager.setNpcSettings(sampleNPCSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_FROMBELOW]=nil,
		[HARM_TYPE_NPC]=nil,
		[HARM_TYPE_PROJECTILE_USED]=nil,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=nil,
		[HARM_TYPE_TAIL]=nil,
		[HARM_TYPE_OFFSCREEN]=nil,
		[HARM_TYPE_SWORD]=nil,
	}
);

AI.registerTank(npcID)

return sampleNPC