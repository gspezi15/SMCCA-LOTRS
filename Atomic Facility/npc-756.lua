--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

local sp = require("shockplatforms")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 4,
	framestyle = 0,
	framespeed = 4, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false

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

--Custom local definitions below


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
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.initialized = false
		return
	end
	
	if not data.initialized then
		data.timer = 0
		data.dir = data.dir or nil
		data.initialized = true
	end

	data.timer = data.timer + 1

	v.direction = 1
	if data.timer == 4 then
		for k,p in ipairs(Player.get()) do
			if Colliders.collide(p, Colliders.Box(v.x-2, v.y-2, v.width+4, v.height+4)) then
				player:harm(true)
			end
		end
	end

	if data.timer == 2 then
		for _,q in ipairs(Block.getIntersecting(data.block.x-8,data.block.y + 0.5 * data.block.height,data.block.x+data.block.width + 8,data.block.y+0.5 * data.block.height + 1)) do
			if sp.shockableIDMap[q.id] and q.data.timer <= 0 then
				if q:mem(0x62,FIELD_WORD) == 0 and q:mem(0x64,FIELD_WORD) == 0 then
					local n = NPC.spawn(npcID, q.x + 0.5 * q.width, q.y + 0.5 * q.height, v:mem(0x146, FIELD_WORD), false, true)
					n.friendly = true
					n.data.block = q
					n.data.block.data.timer = 12
				end
			end
		end
		for _,q in ipairs(Block.getIntersecting(data.block.x + 0.5 * data.block.width,data.block.y - 8,data.block.x + 0.5 * data.block.width + 1,data.block.y+data.block.height + 8)) do
			if sp.shockableIDMap[q.id] and q.data.timer <= 0 then
				if q:mem(0x62,FIELD_WORD) == 0 and q:mem(0x64,FIELD_WORD) == 0 then
					local n = NPC.spawn(npcID, q.x + 0.5 * q.width, q.y + 0.5 * q.height, v:mem(0x146, FIELD_WORD), false, true)
					n.friendly = true
					n.data.block = q
					n.data.block.data.timer = 12
				end
			end
		end
	end

	if data.timer == 12 then
		v:kill(9)
	end
end

--Gotta return the library table!
return sampleNPC