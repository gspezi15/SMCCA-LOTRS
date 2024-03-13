local npcManager = require("npcManager")
local AI = require("AI/fireServer")

local sampleNPC = {}
local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,
	gfxheight = 56,
	gfxwidth = 56,
	gfxoffsetx = 0,
	gfxoffsety = 2,

	width = 24,
	height = 48,

	frames = 5,
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
	nofireball = false,
	noiceball = false,
	noyoshi= true,
	nowaterphysics = true,

	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside = false,
	grabtop = false,

	-- custom settings
	frameOffsets = {[2] = vector(0, 2)},             -- per-frame offsets
	shootArea = {x = 0, y = -256, w = 640, h = 512}, -- the region in which the npc can detect players

	idleFrames = 2,  -- number of idle frames
	idleTime = 112,  -- number of frames the npc will be in idle state
	shootFrames = 2, -- number of shoot frames
	shotCount = 3,   -- number of shots to fire
	shotDelay = 32,  -- delay between firing each shot

	shootOffset = vector(28, -18),    -- offset of the shot relative to the center
	heldNPCOffset = vector(-18, -24), -- offset of the held npc relative to the center

	shootNPCID = npcID + 1, -- id of the npc to be shot
	heldNPCID = npcID + 2,  -- id of the npc to be held

	minHeight = 160,  -- minimum height the shot must reach
	maxHeight = 2048, -- maximum height the shot could reach

	minDistanceX = 128, -- minimum distance between the shot and the player
	maxDistanceX = 640, -- maximum distance the shot can reach

	shootSFX = {id = "AI/fireServer-shoot.wav", volume = 1},
}

npcManager.setNpcSettings(sampleNPCSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=10,
		[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

AI.registerNPC(npcID)

return sampleNPC