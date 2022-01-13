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

local deathEffectID = (npcID-6)


local monitorSettings = table.join({
	id = npcID,


	screenImage = Graphics.loadImageResolved("monitor_screen_plainShield.png"),

	effectSound = nil,


	shieldName = "plain",
	shieldGetSound = SFX.open(Misc.resolveSoundFile("shield")),
	shieldLostSound = SFX.open(Misc.resolveSoundFile("monitor_lostShield")),

	shieldImage1 = Graphics.loadImageResolved("monitor_shield_plain.png"),
	shieldFrames1 = 3,
	shieldFrameDelay1 = 6,
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


function monitor.effectFunction(playerObj,npcID,config,screenObj)
	local players
	if playerObj ~= nil then
		players = {playerObj}
	else
		players = Player.get()
	end

	for _,p in ipairs(players) do
		ai.setShield(p,config.shieldName)
	end
end


function monitor.onDrawShield(p,behaviourData,data,config)
	ai.drawShieldLayer(p,1)
end


monitor.isInvincibileTo = nil


ai.register(npcID,monitor.effectFunction)

ai.registerShield(npcID,monitor.onTickShield,monitor.onTickEndShield,monitor.onDrawShield,monitor.isInvincibileTo)


return monitor