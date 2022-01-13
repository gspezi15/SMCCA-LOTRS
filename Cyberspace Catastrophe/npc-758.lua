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

local deathEffectID = (npcID-7)
local sparksEffectID = (npcID-6)


local monitorSettings = table.join({
	id = npcID,


	screenImage = Graphics.loadImageResolved("monitor_screen_thunderShield.png"),

	effectSound = nil,


	shieldName = "thunder",
	shieldGetSound = SFX.open(Misc.resolveSoundFile("thunder-shield")),
	shieldLostSound = SFX.open(Misc.resolveSoundFile("monitor_lostShield")),
	shieldUseSound = SFX.open(Misc.resolveSoundFile("thunder-shield-jump")),

	shieldImage1 = Graphics.loadImageResolved("monitor_shield_thunder.png"),
	shieldFrames1 = 24,
	shieldFrameDelay1 = 4,

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


local colCircle = Colliders.Circle(0,0,0)
local function coinsFilter(v)
	local config = NPC.config[v.id]

	return (
		v.despawnTimer > 0
		and Colliders.FILTER_COL_NPC_DEF(v)

		and config ~= nil and config.iscoin
	)
end

local function attractedCoinBehaviour(p,behaviourData,attractionRadius,k,npc) -- returns true if it should be removed from the list
	if not npc.isValid or npc.despawnTimer <= 0 or not Colliders.FILTER_COL_NPC_DEF(npc) then
		return true
	end

	local config = NPC.config[npc.id]

	if config == nil or not config.iscoin then
		return true
	end


	npc.noblockcollision = true
	npc.ai1 = 1

	-- Stop despawning
	if npc.despawnTimer > 10 and npc.despawnTimer < 100 then
		npc.despawnTimer = 100
	end

	-- Get attracted
	local speed = vector(npc.speedX,npc.speedY)
	local distance = vector(
		(p.x+(p.width *0.5))-(npc.x+(npc.width *0.5)),
		(p.y+(p.height*0.5))-(npc.y+(npc.height*0.5))
	):normalise()

	local newSpeed = speed
	for i=1,2 do
		local distanceSign = math.sign(distance[i])

		local attraction = 0.2
		if math.sign(speed[i]) ~= distanceSign then
			attraction = attraction*2
		end
		if distance.length > attractionRadius*1.5 then
			attraction = attraction*2
		end

		newSpeed[i] = newSpeed[i] + distanceSign*attraction
	end

	npc.speedX = math.clamp(newSpeed.x,-8,8)
	npc.speedY = math.clamp(newSpeed.y,-8,8)-Defines.npc_grav


	return false
end


function monitor.onTickShield(p,behaviourData,data,config)
	-- Double jump ability
	if behaviourData.abilityReady == nil then
		behaviourData.abilityReady = true
	end


	if ai.canRestoreJumpAbility(p) then
		behaviourData.abilityReady = true
	end


	if behaviourData.abilityReady and (p.keys.jump == KEYS_PRESSED or p.keys.altJump == KEYS_PRESSED) and ai.canUseJumpAbility(p) then
		p:mem(0x11C,FIELD_WORD,Defines.jumpheight*0.75)

		behaviourData.abilityReady = false

		if config.useSound ~= nil then
			SFX.play(config.useSound)
		end

		if sparksEffectID ~= nil then
			local e = Effect.spawn(sparksEffectID,p.x + p.width*0.5,p.y + p.height)

			e.x = e.x - e.width *0.5
			e.y = e.y - e.height
		end
	end

	-- Ring attraction
	behaviourData.attractingCoins = behaviourData.attractingCoins or {}
	behaviourData.attractingCoinsMap = behaviourData.attractingCoinsMap or {}

	colCircle.x = p.x+(p.width *0.5)
	colCircle.y = p.y+(p.height*0.5)
	colCircle.radius = config.npcConfig.shieldCoinsAttractionRadius


	local newCoins = Colliders.getColliding{a = colCircle,btype = Colliders.NPC,filter = coinsFilter}

	-- Add those new coins
	for _,npc in ipairs(newCoins) do
		if not behaviourData.attractingCoinsMap[npc] then
			npc.speedX = 0
			npc.speedY = 0

			behaviourData.attractingCoinsMap[npc] = true
			table.insert(behaviourData.attractingCoins,npc)
		end
	end

	-- Pull each ring closer
	for k = #behaviourData.attractingCoins, 1, -1 do
		local npc = behaviourData.attractingCoins[k]

		local shouldRemove = attractedCoinBehaviour(p,behaviourData,config.npcConfig.shieldCoinsAttractionRadius,k,npc)

		if shouldRemove then
			behaviourData.attractingCoinsMap[npc] = nil
			table.remove(behaviourData.attractingCoins,k)
		end
	end
end

function monitor.onDrawShield(p,behaviourData,data,config)
	local frameCount = config.frames[1]
	local frame = math.floor(data.animationTimer / config.frameDelays[1]) % frameCount

	if frame >= (frameCount*0.5 + 3) then
		data.priorityOffset[1] = -0.5
	else
		data.priorityOffset[1] = 0.5
	end
	
	ai.drawShieldLayer(p,1,frame)
end


-- There's no ishot/iscold-like property suitable for this, so this list will do
monitor.thunderNPCs = table.map{
	361, -- sumo bro's lightning
	431, -- electric spiny
	473, -- waddle doo beam
	493, -- van de graf
}

function monitor.isInvincibileTo(p,culprit)
	if type(culprit) == "NPC" then
		return monitor.thunderNPCs[culprit.id]
	end

	return false
end


ai.register(npcID,monitor.effectFunction)

ai.registerShield(npcID,monitor.onTickShield,monitor.onTickEndShield,monitor.onDrawShield,monitor.isInvincibileTo)


-- Effect behaviour
do
	local effectconfig = require("game/effectconfig")

	function effectconfig.onTick.TICK_LIGHTNINGSHIELDSPARKS(v)
		local age = (v.lifetime-v.timer)

		if age%3 == 0 then
			v.animationFrame = 0
		else
			v.animationFrame = math.min(v.frames-2,math.floor(age/v.framespeed))+1
		end

		v.speedX = v.speedX * 0.94
		v.speedY = v.speedY * 0.94
	end
end


return monitor