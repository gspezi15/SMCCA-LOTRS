--[[

	Written by MrDoubleA
	Please give credit!

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local ai = require("monitor_ai")


local monitor = {}
local npcID = NPC_ID

local deathEffectID = (npcID-2)


local monitorSettings = table.join({
	id = npcID,


	screenImage = Graphics.loadImageResolved("monitor_screen_1up.png"),

	effectSound = 15,
},ai.sharedSettings)


npcManager.setNpcSettings(monitorSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_NPC,
		HARM_TYPE_TAIL,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP]            = deathEffectID,
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_SPINJUMP]        = deathEffectID,
		[HARM_TYPE_OFFSCREEN]       = deathEffectID,
		[HARM_TYPE_SWORD]           = deathEffectID,
	}
)


local LIVES_ADDR = 0x00B2C5AC
function monitor.effectFunction(playerObj,npcID,config,screenObj)
	mem(LIVES_ADDR,FIELD_FLOAT,math.min(99,mem(LIVES_ADDR,FIELD_FLOAT)+1))
end


ai.register(npcID,monitor.effectFunction)


return monitor