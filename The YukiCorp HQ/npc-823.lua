local reverseBoo = {}

local npcManager = require("npcManager")

local boo = require("npcs/ai/boo")

-- Defaults --
local npcID = NPC_ID

npcManager.registerHarmTypes(npcID,{HARM_TYPE_NPC},{[HARM_TYPE_NPC]=243})

reverseBoo.config = npcManager.setNpcSettings(
	{id = npcID,
	gfxheight = 64,
	gfxwidth = 32,
	width = 32,
	height = 64,
	frames = 2,
	framespeed = -1,
	framestyle = 1,
	nogravity = true,
	jumphurt = true,
	speed = 1,
	nowaterphysics = true,
	spinjumpsafe = true,
	nogravity = true,
	noblockcollision=true,
	nofireball = false,
	noiceball = true,
	noyoshi = true,

	maxspeedx = 2,
	maxspeedy = 2,
	accelx = 0.15,
	accely = 0.15,
	decelx = 0.15,
	decely = 0.15,
})

local function conditionFunction(v)
	local centerX = v.x + 0.5 * v.width
	for k,p in ipairs(Player.get()) do
			return p
		end
	return false
end

boo.register(npcID, conditionFunction)

return reverseBoo
