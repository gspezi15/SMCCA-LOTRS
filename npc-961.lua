-- by Marioman2007
-- Life-Up Mushroom
-- Maximizes the the player's health meter

local npcManager = require("npcManager")
local SmgLifeSystem = require("SmgLifeSystem")
local particles = require("particles")
playerParticle = particles.Emitter(0, 0, Misc.resolveFile("p_sparkle.ini"))

local LifeUpMushroom = {}
local npcID = NPC_ID

local LifeUpMushroomSettings = {
	id = npcID,
	gfxheight = 32,
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

	soundEffect = SFX.open(Misc.resolveSoundFile("SFX/smg_life_mushroom")), -- The sound effect that will play when the player collects the power-up.
	soundEffectAlt = SFX.open(Misc.resolveSoundFile("SFX/smrpg_item")), -- The sound effect that will play when the player collects the power-up while the health is max.

	soundEffectVolume = 0.45, -- Volume of "soundEffect"
	soundEffectVolumeAlt = 0.4, -- Volume of "soundEffectAlt"

	playerParticlesTime = 100, -- Duration of the particles emmiting at the player, to disable player particles, set this value to 1
}

npcManager.setNpcSettings(LifeUpMushroomSettings)
npcManager.registerHarmTypes(npcID, {}, {})

local playerParticlesOn = false
local playerParticlesTimer = 0

local function isEmergingFromBlock(v)
	local containedIn = v:mem(0x138, FIELD_WORD)
	return containedIn == 1 or containedIn == 3
end

function LifeUpMushroom.onTickNPC(v)
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

function LifeUpMushroom.onDrawNPC(v)
	local data = v.data

	if not isEmergingFromBlock(v) then
		data.Emmiter:Attach(v)
		data.Emmiter:Draw(-44)
	end
end

function LifeUpMushroom.onPostNPCKill(v,reason)
	if v.id ~= npcID then
        return
    end

    if npcManager.collected(v,reason) then
		if not SmgLifeSystem.daredevilActive then
			if not SmgLifeSystem.doFancyAnim then
				if SmgLifeSystem.CurrentHealth ~= SmgLifeSystem.MaxHealth then
					SmgLifeSystem.setHealth(SmgLifeSystem.MaxHealth, 1)
					SFX.play(NPC.config[npcID].soundEffect, NPC.config[npcID].soundEffectVolume)
				elseif SmgLifeSystem.CurrentHealth == SmgLifeSystem.MaxHealth then
					if NPC.config[npcID].CoinsReward > 0 then
						Misc.coins(NPC.config[npcID].CoinsReward, false)
						SFX.play(NPC.config[npcID].soundEffectAlt, NPC.config[npcID].soundEffectVolumeAlt)
					end
				end
			elseif SmgLifeSystem.doFancyAnim then
				if SmgLifeSystem.CurrentHealth ~= SmgLifeSystem.MaxHealth then
					SFX.play(NPC.config[npcID].soundEffect, NPC.config[npcID].soundEffectVolume)
				elseif SmgLifeSystem.CurrentHealth == SmgLifeSystem.MaxHealth then
					if NPC.config[npcID].CoinsReward > 0 then
						Misc.coins(NPC.config[npcID].CoinsReward, false)
						SFX.play(NPC.config[npcID].soundEffectAlt, NPC.config[npcID].soundEffectVolumeAlt)
					end
				end

				if SmgLifeSystem.CurrentHealth <= SmgLifeSystem.MainHealth then
					SmgLifeSystem.CountUp()
				else
					SmgLifeSystem.setHealth(SmgLifeSystem.MaxHealth, 1)
				end
			end
		end

		Misc.givePoints( 6, v, true)
		playerParticlesOn = true
		playerParticle:setParam("speedX", "-25:25")
		playerParticle:setParam("yOffset", "-32:32")
		playerParticle:setParam("rate", "10")
    end
end

function LifeUpMushroom.onTick()
	if playerParticlesOn then
		playerParticlesTimer = playerParticlesTimer + 1
	end

	if playerParticlesTimer == NPC.config[npcID].playerParticlesTime then
		playerParticlesOn = false
		playerParticlesTimer = 0
	end
end

function LifeUpMushroom.onDraw()
	playerParticle:Attach(player)

	if playerParticlesOn then
		playerParticle:Draw(-24)
	end
end

function LifeUpMushroom.onInitAPI()
	npcManager.registerEvent(npcID, LifeUpMushroom, "onTickNPC")
	npcManager.registerEvent(npcID, LifeUpMushroom, "onDrawNPC")

	registerEvent(LifeUpMushroom, "onTick", "onTick")
	registerEvent(LifeUpMushroom, "onDraw", "onDraw")
	registerEvent(LifeUpMushroom, "onPostNPCKill", "onPostNPCKill")
end

return LifeUpMushroom