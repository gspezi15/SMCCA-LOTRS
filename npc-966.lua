-- by Marioman2007
-- Full Heal Shroom
-- Heals the player fully.

local npcManager = require("npcManager")
local SmgLifeSystem = require("SmgLifeSystem")
local particles = require("particles")
playerParticle = particles.Emitter(0, 0, Misc.resolveFile("p_sparkle.ini"))

local FullHealShroom = {}
local npcID = NPC_ID

local FullHealShroomSettings = {
	id = npcID,
	gfxheight = 38,
	gfxwidth = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	speed = 0,

	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= false,
	nowaterphysics = false,
	notcointransformable = true,

	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	isinteractable = true,

	CoinsReward = 10, -- The amount of coins given to the player when the player collects a mushroom when the HP is full

	soundEffect = SFX.open(Misc.resolveSoundFile("SFX/smrpg_item_drink")), -- The sound effect that will play when the player collects the power-up.
	soundEffectVolume = 0.5, -- Volume of the sound effect played, must be between 0 and 1.

	playerParticlesTime = 100, -- Duration of the particles emmiting at the player, to disable player particles, set this value to 1
}

npcManager.setNpcSettings(FullHealShroomSettings)
npcManager.registerHarmTypes(npcID, {}, {})

local playerParticlesOn = false
local playerParticlesTimer = 0

local function isEmergingFromBlock(v)
	local containedIn = v:mem(0x138, FIELD_WORD)
	return containedIn == 1 or containedIn == 3
end

function FullHealShroom.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.Emmiter = particles.Emitter(0, 0, Misc.resolveFile("p_sparkle.ini"))
	end
end

function FullHealShroom.onDrawNPC(v)
	local data = v.data

	if not isEmergingFromBlock(v) then
		data.Emmiter:Attach(v)
		data.Emmiter:Draw(-44)
	end
end

function FullHealShroom.onPostNPCKill(v,reason)
	if v.id ~= npcID then
        return
    end

    if npcManager.collected(v,reason) then
		if not SmgLifeSystem.daredevilActive then
			if (SmgLifeSystem.CurrentHealth < SmgLifeSystem.MainHealth) then
				SmgLifeSystem.setHealth(SmgLifeSystem.MainHealth, 1)
			elseif (SmgLifeSystem.CurrentHealth < SmgLifeSystem.MaxHealth) and (SmgLifeSystem.CurrentHealth > SmgLifeSystem.MainHealth) then
				SmgLifeSystem.setHealth(SmgLifeSystem.MaxHealth, 1)
			end
		end

		if (SmgLifeSystem.CurrentAir < SmgLifeSystem.AirMax) then
			SmgLifeSystem.setHealth(SmgLifeSystem.MaxHealth, 2)
		end

		Misc.givePoints( 6, v, true)
		SFX.play(NPC.config[npcID].soundEffect, NPC.config[npcID].soundEffectVolume)
		playerParticlesOn = true
		playerParticle:setParam("speedX", "-25:25")
		playerParticle:setParam("yOffset", "-32:32")
		playerParticle:setParam("rate", "10")
    end
end

function FullHealShroom.onTick()
	if playerParticlesOn then
		playerParticlesTimer = playerParticlesTimer + 1
	end

	if playerParticlesTimer == NPC.config[npcID].playerParticlesTime then
		playerParticlesOn = false
		playerParticlesTimer = 0
	end
end

function FullHealShroom.onDraw()
	playerParticle:Attach(player)

	if playerParticlesOn then
		playerParticle:Draw(-24)
	end
end

function FullHealShroom.onInitAPI()
	npcManager.registerEvent(npcID, FullHealShroom, "onTickNPC")
	npcManager.registerEvent(npcID, FullHealShroom, "onDrawNPC")

	registerEvent(FullHealShroom, "onTick", "onTick")
	registerEvent(FullHealShroom, "onDraw", "onDraw")
	registerEvent(FullHealShroom, "onPostNPCKill", "onPostNPCKill")
end

return FullHealShroom