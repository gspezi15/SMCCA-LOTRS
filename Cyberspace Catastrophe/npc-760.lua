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

local deathEffectID = (npcID-9)


local monitorSettings = table.join({
	id = npcID,


	screenImage = Graphics.loadImageResolved("monitor_screen_bubbleShield.png"),

	effectSound = nil,


	bounceFrames = 2,

	bounceSpeed = -7,


	shieldName = "bubble",
	shieldGetSound = SFX.open(Misc.resolveSoundFile("bubble-shield")),
	shieldLostSound = SFX.open(Misc.resolveSoundFile("monitor_lostShield")),
	shieldUseSound = SFX.open(Misc.resolveSoundFile("bubble-shield-jump")),

	shieldImage1 = Graphics.loadImageResolved("monitor_shield_bubble1.png"),
	shieldFrames1 = 4,
	shieldFrameDelay1 = 16,

	shieldImage2 = Graphics.loadImageResolved("monitor_shield_bubble2.png"),
	shieldFrames2 = 10,
	shieldFrameDelay2 = 6,

	shieldCoinsAttractionRadius = 160,
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



local colBox = Colliders.Box(0,0,0,0)

local function bounce(p,behaviourData,data,config)
	behaviourData.bounceTimer = 0
	p.speedY = config.npcConfig.bounceSpeed

	behaviourData.afterBounceTimer = 4

	if config.useSound ~= nil then
		SFX.play(config.useSound)
	end
end

function monitor.onTickShield(p,behaviourData,data,config)
	-- Double jump ability
	if behaviourData.abilityReady == nil then
		behaviourData.abilityReady = true

		behaviourData.bounceTimer = 0
		behaviourData.afterBounceTimer = 0
	end


	if behaviourData.bounceTimer > 0 then
		if p:mem(0x11C,FIELD_WORD) > 0 then -- jump force
			bounce(p,behaviourData,data,config)

			p.speedY = p.speedY * 2

			p:mem(0x11C,FIELD_WORD,0)
		elseif p:isOnGround() then
			bounce(p,behaviourData,data,config)
		elseif not ai.canUseJumpAbility(p) then
			behaviourData.bounceTimer = 0
		else
			behaviourData.bounceTimer = behaviourData.bounceTimer + 1

			-- Hit blocks
			colBox.x = p.x
			colBox.y = p.y + p.height + p.speedY
			colBox.width = p.width
			colBox.height = 2

			local blocks = Colliders.getColliding{a = colBox,b = Block.SOLID,btype = Colliders.BLOCK}

			for _,block in ipairs(blocks) do
				if Block.MEGA_SMASH_MAP[block.id] and block.contentID == 0 and block.id ~= 90 then
					block:remove(true)
				else
					block:hit(true)
				end

				bounce(p,behaviourData,data,config)
			end
		end
	else
		if p:isOnGround() or p.speedY >= 0 then
			behaviourData.abilityReady = true
		end


		behaviourData.afterBounceTimer = math.max(0, behaviourData.afterBounceTimer - 1)

		if behaviourData.abilityReady and (p.keys.jump == KEYS_PRESSED or p.keys.altJump == KEYS_PRESSED) and ai.canUseJumpAbility(p) then
			p.speedX = 0
			p.speedY = Defines.gravity

			p:mem(0x11C,FIELD_WORD,0)

			behaviourData.bounceTimer = 1
			behaviourData.afterBounceTimer = 0

			behaviourData.abilityReady = false
		end
	end
end


function monitor.onDrawShield(p,behaviourData,data,config)
	local normalFrames = (config.frames[1] - config.npcConfig.bounceFrames)

	local mainFrame = math.floor(data.animationTimer / config.frameDelays[1]) % normalFrames

	local drawOverlay = true

	if behaviourData.bounceTimer > 0 then
		mainFrame = math.min(config.npcConfig.bounceFrames - 1, math.floor(behaviourData.bounceTimer / 4)) + normalFrames
		drawOverlay = false
	elseif behaviourData.afterBounceTimer > 0 then
		mainFrame = normalFrames
		drawOverlay = false
	end

	ai.drawShieldLayer(p,1,mainFrame)

	if drawOverlay then
		ai.drawShieldLayer(p,2)
	end
end


function monitor.isInvincibileTo(p,culprit)
	if type(culprit) == "NPC" then
		local config = NPC.config[culprit.id]

		return config.iscold
	end

	return false
end


ai.register(npcID,monitor.effectFunction)

ai.registerShield(npcID,monitor.onTickShield,monitor.onTickEndShield,monitor.onDrawShield,monitor.isInvincibileTo)


return monitor