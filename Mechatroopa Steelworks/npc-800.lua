local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local npcInjector = {}
local npcID = NPC_ID

local npcInjectorSettings = {
	id = npcID,

	gfxwidth = 32,
	gfxheight = 32,

	width = 32,
	height = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 1,
	framestyle = 0,
	framespeed = 8,

	nowaterphysics = true,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	notcointransformable = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,

	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = true,
	harmlessthrown = true,
	ignorethrownnpcs = true,


	checkRadius = 32,
}

npcManager.setNpcSettings(npcInjectorSettings)

function npcInjector.onInitAPI()
	npcManager.registerEvent(npcID, npcInjector, "onStartNPC")
	registerEvent(npcInjector, "onPostNPCKill")
end


local SPAWN_ACTION = {
	NOTHING = 0,
	PROJECTILE = 1,
	COLLECT = 2,
}

local function spawnContainedNPC(v)
	local injectedID = v.data._injectedID

	if injectedID == nil or injectedID == 0 then
		return
	end

	local containedConfig = NPC.config[injectedID]
	local settings = v.data._injectorSettings

	-- Where should the NPC be?
	local x = v.x + v.width*0.5
	local y = v.y + v.height*0.5

	if not containedConfig.noblockcollision then
		y = v.y + v.height - containedConfig.height*0.5
	end

	local nearestPlayer = Player.getNearest(x,y)

	-- Actually spawn it
	local n = NPC.spawn(injectedID,x,y,v.section,false,true)

	n.direction = v.direction
	n.spawnDirection = n.direction

	n.speedX = settings.spawnSpeedX*n.direction
	n.speedY = settings.spawnSpeedY

	-- Spawn actions
	if settings.spawnAction == SPAWN_ACTION.PROJECTILE then
		n:mem(0x136,FIELD_BOOL,true)
		n:mem(0x12E,FIELD_WORD,20)
		n:mem(0x130,FIELD_WORD,nearestPlayer.idx)
	elseif settings.spawnAction == SPAWN_ACTION.COLLECT and n.collect ~= nil then
		n:collect(nearestPlayer)
		n:kill(HARM_TYPE_VANISH)

		n.animationFrame = -999
	else
		-- Briefly make the NPC uninteractable
		n:mem(0x12E,FIELD_WORD,20)
		n:mem(0x130,FIELD_WORD,nearestPlayer.idx)
	end

	return n
end

function npcInjector.onStartNPC(v)
	if v.ai1 <= 0 then
		return
	end

	-- Find nearby NPCs and give them the appropriate settings
	local config = NPC.config[v.id]

	local checkCollider = Colliders.Circle(v.x + v.width*0.5,v.y + v.height*0.5,config.checkRadius)
	local containerNPCs = Colliders.getColliding{a = checkCollider,btype = Colliders.NPC}

	for _,containerNPC in ipairs(containerNPCs) do
		if containerNPC.id ~= npcID and not containerNPC.isGenerator and containerNPC.layerName == v.layerName then
			containerNPC.data._injectedID = v.ai1
			containerNPC.data._injectorSettings = v.data._settings
		end
	end

	v:kill(HARM_TYPE_VANISH)
end


local function canSpawn(reason,spawnWhenSettings)
	if reason == HARM_TYPE_VANISH then
		return spawnWhenSettings.vanish
	end

	if reason == HARM_TYPE_LAVA then
		return spawnWhenSettings.lava
	end

	return spawnWhenSettings.other
end

function npcInjector.onPostNPCKill(v,reason)
	local settings = v.data._injectorSettings

	if settings ~= nil and canSpawn(reason,settings.spawnWhen) then
		spawnContainedNPC(v)
	end
end


return npcInjector