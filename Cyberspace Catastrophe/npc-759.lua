--[[

	Written by MrDoubleA
	Please give credit!

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local playerManager = require("playerManager")

local ai = require("monitor_ai")


local monitor = {}
local npcID = NPC_ID

local deathEffectID = (npcID-8)


local monitorSettings = table.join({
	id = npcID,


	screenImage = Graphics.loadImageResolved("monitor_screen_flameShield.png"),

	effectSound = nil,


	burstSpeed = 9,
	burstLength = 16,


	shieldName = "flame",
	shieldGetSound = SFX.open(Misc.resolveSoundFile("flame-shield")),
	shieldLostSound = SFX.open(Misc.resolveSoundFile("monitor_lostShield")),
	shieldUseSound = SFX.open(Misc.resolveSoundFile("flame-shield-dash")),


	shieldImage1 = Graphics.loadImageResolved("monitor_shield_flame1.png"),
	shieldFrames1 = 9,
	shieldFrameDelay1 = 4,

	shieldImage2 = Graphics.loadImageResolved("monitor_shield_flame2.png"),
	shieldFrames2 = 9,
	shieldFrameDelay2 = 4,

	shieldImage3 = Graphics.loadImageResolved("monitor_shield_flameBurst.png"),
	shieldFrames3 = 8,
	shieldFrameDelay3 = 4,
},ai.sharedSettings)


npcManager.setNpcSettings(monitorSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_NPC,
		HARM_TYPE_TAIL,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD,
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


function monitor.onTickShield(p,behaviourData,data,config)
	-- Fire burst attack
	if behaviourData.abilityReady == nil then
		behaviourData.abilityReady = true

		behaviourData.burstTimer = 0
		behaviourData.burstDirection = 0

		behaviourData.justFinishedBurst = false
	end


	if ai.canRestoreJumpAbility(p) then
		behaviourData.abilityReady = true
	end

	if (behaviourData.abilityReady and behaviourData.burstDirection == 0) and (p.keys.jump == KEYS_PRESSED or p.keys.altJump == KEYS_PRESSED) and ai.canUseJumpAbility(p) then
		behaviourData.burstTimer = 0

		if p.keys.left then
			behaviourData.burstDirection = DIR_LEFT
		elseif p.keys.right then
			behaviourData.burstDirection = DIR_RIGHT
		else
			behaviourData.burstDirection = p.direction
		end

		behaviourData.abilityReady = false

		if config.useSound ~= nil then
			SFX.play(config.useSound)
		end
	end


	if behaviourData.burstDirection ~= 0 and ai.canUseJumpAbility(p) then
		behaviourData.burstTimer = behaviourData.burstTimer + 1


		local gravity = Defines.player_grav

		if playerManager.getBaseID(p.character) == CHARACTER_LUIGI then
			gravity = gravity * 0.9
		end

		p.speedX = config.npcConfig.burstSpeed * behaviourData.burstDirection
		p.speedY = -gravity + 0.0001

		if p.holdingNPC == nil then
			p.keys.run = false
		end


		-- Hit NPC's
		local npcs = Colliders.getColliding{a = Colliders.getSpeedHitbox(p),b = NPC.HITTABLE,btype = Colliders.NPC}

		for _,npc in ipairs(npcs) do
			npc:harm(HARM_TYPE_NPC)
		end


		if behaviourData.burstTimer >= config.npcConfig.burstLength then
			behaviourData.burstDirection = 0

			p.speedX = math.clamp(p.speedX, -Defines.player_runspeed,Defines.player_runspeed)

			behaviourData.justFinishedBurst = true
		else
			behaviourData.justFinishedBurst = false
		end
	else
		behaviourData.burstDirection = 0
		behaviourData.justFinishedBurst = false
	end
end


function monitor.onTickEndShield(p,behaviourData,data,config)
	if behaviourData.justFinishedBurst then
		p:mem(0x172,FIELD_BOOL,false)
	end
end


function monitor.onDrawShield(p,behaviourData,data,config)
	if behaviourData.burstDirection ~= nil and behaviourData.burstDirection ~= 0 then
		local layerIndex = 3

		local frameCount = config.frames[layerIndex] * 0.5
		local frame = math.min(frameCount - 1, math.floor(behaviourData.burstTimer / config.frameDelays[layerIndex]))

		if behaviourData.burstDirection == DIR_RIGHT then
			frame = frame + frameCount
		end

		ai.drawShieldLayer(p,3,frame)

		return
	end

	for layerIndex = 1, 2 do
		local frameCount = config.frames[layerIndex]
		local frame = math.floor(data.animationTimer / config.frameDelays[layerIndex]) % ((frameCount * 2) - 2)

		local animationPlayingBackwards = false

		if frame >= frameCount then
			frame = frameCount - (frame - frameCount) - 2
			animationPlayingBackwards = true
		end

		if animationPlayingBackwards == (layerIndex == 1) then
			data.priorityOffset[layerIndex] = -0.5
		else
			data.priorityOffset[layerIndex] = 0.5
		end

		ai.drawShieldLayer(p,layerIndex,frame)
	end
end


function monitor.isInvincibileTo(p,culprit)
	if type(culprit) == "NPC" then
		local config = NPC.config[culprit.id]

		return config.ishot
	end

	return false
end


ai.register(npcID,monitor.effectFunction)

ai.registerShield(npcID,monitor.onTickShield,monitor.onTickEndShield,monitor.onDrawShield,monitor.isInvincibileTo)


return monitor