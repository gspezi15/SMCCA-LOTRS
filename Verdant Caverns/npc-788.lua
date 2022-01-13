--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local rng = require("rng")

--Create the library table
local hornet = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local hornetSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 36,
	gfxwidth = 44,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 24,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 2,
	--Frameloop-related
	frames = 4,
	framestyle = 1,
	framespeed = 2, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

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
npcManager.setNpcSettings(hornetSettings)

--Registers the category of the NPC. Options include HITTABLE, UNHITTABLE, POWERUP, COLLECTIBLE, SHELL. For more options, check expandedDefines.lua
npcManager.registerDefines(npcID, {NPC.HITTABLE})

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
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=788,
		[HARM_TYPE_FROMBELOW]=788,
		[HARM_TYPE_NPC]=788,
		[HARM_TYPE_PROJECTILE_USED]=788,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=788,
		[HARM_TYPE_TAIL]=788,
		[HARM_TYPE_SPINJUMP]=788,
		--[HARM_TYPE_OFFSCREEN]=788,
		[HARM_TYPE_SWORD]=788,
	}
);

--Custom local definitions below


--Register events
function hornet.onInitAPI()
	--npcManager.registerEvent(npcID, hornet, "onTickNPC")
	npcManager.registerEvent(npcID, hornet, "onTickEndNPC")
	--npcManager.registerEvent(npcID, hornet, "onDrawNPC")
	--registerEvent(hornet, "onNPCKill")
end

function hornet.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--Execute main AI.
	if not v.dontMove then
		local cx = v.x + 0.5 * v.width
    		local cy = v.y + 0.5 * v.height
    		local p = Player.getNearest(cx, cy)
    		local d = -vector(cx - p.x + p.width, cy - p.y):normalize() * 0.1
    		local speed = NPC.config[v.id].speed
    		v.speedX = v.speedX + d.x * NPC.config[v.id].speed
    		v.speedY = v.speedY + d.y * NPC.config[v.id].speed
    		if v.collidesBlockUp then
        		v.speedY = math.abs(v.speedY) + 3 --Bouncing off celing
    		end
		if v.collidesBlockBottom then
			v.speedY = math.abs(v.speedY) - 3 --Bouncing off ground
		end
		if v.collidesBlockLeft then
			v.speedX = math.abs(v.speedX) - 3 --Bouncing off wall
		end
		if v.collidesBlockRight then
			v.speedX = math.abs(v.speedX) + 3 --Bouncing off wall 2: Electric Boogaloo
		end
    		v.speedX = math.clamp(v.speedX, -3, 3)
    		v.speedY = math.clamp(v.speedY, -3, 3)
	end
	if lunatime.tick() % 224 == 192 then
		--Shooting stinger
		local stinger = NPC.spawn(789, v.x + 0 * v.width, v.y + 0.5 * v.height, player.section, false, true)
		stinger.speedX = 9 * v.direction
		stinger.speedY = rng.randomInt(-1.5,1.5)
		stinger.friendly = v.friendly
		stinger.layerName = "Spawned NPCs";
	end
end

--jOE MAMA JOE MAMA JOE MAMA JOE MAMA JOE MAMA JOE MAMA JOE MAMA JOE MAMA JOE MAMA JOE MAMA
return hornet