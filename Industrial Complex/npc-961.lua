--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Robot sound effect taken from Spencer Everly's sound archive

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 128,
	gfxwidth = 128,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 76,
	height = 88,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 14,
	framestyle = 1,
	framespeed = 8, 
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	cliffturn=true,
	turninterval = 60,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
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
		--[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

local STATE_IDLE = 0
local STATE_RUN = 1
local STATE_ATTACK = 2
local STATE_HARM = 3

local spawnOffset = {}
spawnOffset[-1] = (sampleNPCSettings.width - 126)
spawnOffset[1] = (sampleNPCSettings.width - 64)

--Handle animation frame
local function getAnimationFrame(v)
	local data = v.data
	if data.state == STATE_IDLE then
		if data.timer <= 0 then
			v.animationFrame = 0
		else
			if v.data.timer % 50 < 18 then 
				v.animationFrame = 1
			else
				v.animationFrame = 2
			end
		end
	elseif data.state == STATE_RUN then
		v.animationFrame = math.floor(data.timer / 8) % 8 + 5
	elseif data.state == STATE_ATTACK then
		if data.timer <= 8 then
			v.animationFrame = 3
		else
			v.animationFrame = 4
		end
	else
		if v.data.timer % 7 < 4 then 
			v.animationFrame = 13
		else
			v.animationFrame = -1
		end
	end
	
	if v.animationFrame >= 0 then
		v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})
	end
end

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onNPCHarm")
	registerEvent(sampleNPC, "onNPCKill")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
	
	--Collider to activate the npc
	local searchBox = Colliders.Box(v.x - (v.width * 1), v.y - (v.height * 1), v.width * 6.5, v.height * 3.5)
	searchBox.x = v.x - v.width / 0.35
	searchBox.y = v.y - v.height / 0.75
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.state = STATE_IDLE
		data.timer = 0
		data.turnTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_IDLE
		data.timer = data.timer or 0
		data.turnTimer = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.timer = 0
		data.state = STATE_IDLE
	end
	
	if not data.health then
		data.health = 2
	end
	
	getAnimationFrame(v)
	
	--Count the timer up when meeting certain conditions
	if data.state > 0 or v.ai5 > 0 then
		data.timer = data.timer + 1
	end
	
	--When standing still
	if data.state == STATE_IDLE then
		v.speedX = 0
		--If the player comes close
		if Colliders.collide(plr,searchBox) then
			if v.ai5 == 0 then
				SFX.play("Robot 2.wav")
				v.ai5 = 1
			end
		end
		--Make it start running after the timer reaches a value 50 or over
		if data.timer >= 50 then
			data.timer = 0
			npcutils.faceNearestPlayer(v)
			data.state = STATE_RUN
		end
	elseif data.state == STATE_RUN then
		v.speedX = 2.5 * v.direction
		data.turnTimer = data.turnTimer + 1
		if data.turnTimer == sampleNPCSettings.turninterval then
			--Chase the player
			if v.x > plr.x then
				v.direction = -1
			else
				v.direction = 1
			end
			data.turnTimer = 0
		end
		if data.timer >= RNG.randomInt(128, 512) then
			data.state = STATE_ATTACK
			data.timer = 0
		end
	elseif data.state == STATE_ATTACK then
		v.speedX = 0
		--Shoot the homing fists
		if data.timer % 16 == 0 then
			local originX = v.x + 0.5 * v.width
			local originY = v.y + 0.5 * v.height - 16
			
			local n = NPC.spawn(npcID - 1, originX + spawnOffset[v.direction], originY)
			n.direction = v.direction
			
			if data.timer % 32 == 0 then
				n.ai1 = 1
			elseif data.timer % 32 == 16 then
				n.ai1 = 0
			end
	
			n.speedX = 4.5 * v.direction
			local traveltime = math.max((plr.x - originX) / n.speedX, 1)
			n.speedY = (plr.y - originY) / traveltime
			n.speedY = math.min(math.max(n.speedY, -2), 2)
			SFX.play("Metal Slug Bazooka.wav")
			Effect.spawn(10, originX + spawnOffset[v.direction], originY)
		end
		if data.timer >= 47 then
			data.state = STATE_RUN
			data.timer = 0
		end
	else
		--When hurt
		v.speedX = 0
		if data.health > 0 then
			v.ai3 = v.ai3 + 1
			if data.timer >= 64 then
				data.state = STATE_RUN
				data.timer = 0
				v.ai3 = 0
			end
		else
			if data.timer >= 96 then
				v:kill(HARM_TYPE_OFFSCREEN)
			end
		end
	end
end

--Explode when it dies
function sampleNPC.onNPCKill(eventObj,v,reason)
    if npcID ~= v.id then return end
	Explosion.spawn(v.x + 0.5 * v.width, v.y + 0.5 * v.height, 3)
end

--Handle damage
function sampleNPC.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	
	if reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP then
		if culprit.x <= v.x then
			culprit.speedX = -4
		else
			culprit.speedX = 4
		end
		SFX.play(2)
		if data.state ~= STATE_HARM then
			data.health = data.health - 1
			data.timer = 0
			data.state = STATE_HARM
		end
		eventObj.cancelled = true
		return
	end
	
	if reason == HARM_TYPE_NPC then
		data.health = 0
		data.timer = 0
		data.state = STATE_HARM
		eventObj.cancelled = true
	end
end

--Gotta return the library table!
return sampleNPC