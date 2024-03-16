--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 64,
	gfxwidth = 48,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 48,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 4,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = true, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local enemyshot = Misc.resolveFile("mmenemyshot.wav")

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

function sampleNPC.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.movementtimer = 100
		data.shoottimer = 0
		data.verticaldirection = 0 --0 for none, 1 for up, 2 for down. Might be reversed a bit, doesn't really matter
		data.verticaltimer = 50
		data.verticalmoves = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--Execute main AI. This template just jumps when it touches the ground.
	v.speedX = sampleNPCSettings.speed * v.direction
	data.movementtimer = data.movementtimer + 1
	data.shoottimer = data.shoottimer + 1
	if data.verticaldirection == 1 and data.verticalmoves ~= -3 then
		v.speedY = 1
		data.verticaltimer = data.verticaltimer - 1
		if data.verticaltimer == 0 then
			data.verticaltimer = 50
			data.verticaldirection = math.random(0,2)
			data.verticalmoves =  data.verticalmoves - 1
		end
	elseif data.verticaldirection == 2 and data.verticalmoves ~= 3 then
		v.speedY = -1
		data.verticaltimer = data.verticaltimer - 1
		if data.verticaltimer == 0 then
			data.verticaltimer = 50
			data.verticaldirection = math.random(0,2)
			data.verticalmoves =  data.verticalmoves + 1
		end
	else
		v.speedY = 0
		data.verticaltimer = data.verticaltimer - 1
		if data.verticaltimer == 0 then
			data.verticaltimer = 50
			data.verticaldirection = math.random(0,2)
		end
	end
	
	if data.verticaltimer == 0 then
		data.verticaldirection = 0
		data.verticaltimer = 50
	end
	
	if data.movementtimer == 250 then
		v.direction = v.direction * -1
		data.movementtimer = 0
	end
	if data.shoottimer == 150 then
		data.shot1 = NPC.spawn(835, v.x, v.y + (sampleNPCSettings.height/3) - 2, v.section)
		data.shot1.speedX = -3
		data.shot2 = NPC.spawn(835, v.x + sampleNPCSettings.width, v.y + (sampleNPCSettings.height/3) - 2, v.section)
		data.shot2.speedX = 3
		if player.standingNPC == v then
			data.shot1.friendly = true
			data.shot2.friendly = true
		end
		SFX.play(enemyshot)
	elseif data.shoottimer == 175 then
		if data.shot1 ~= nil then --Just preventing any crashes in advance
			data.shot1.friendly = false
		end
		if data.shot2 ~= nil then
			data.shot2.friendly = false
		end
		data.shoottimer = 15
	end
end

--Gotta return the library table!
return sampleNPC