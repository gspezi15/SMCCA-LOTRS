--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 64,
	gfxwidth = 64,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 16,
	--Frameloop-related
	frames = 8,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.
	ignorethrownnpcs = true,

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	
	rotationSpeed=90,
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
local horizontalframeleft = {1, 2, 3}
local horizontalframeright = {5, 6, 7}
local verticalframeup = {3, 4, 5}
local verticalframedown = {1, 0, 7}

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
end

function sampleNPC.onTickEndNPC(v)
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
		v.ai1 = 0
		v.ai2 = 0
		v.ai3 = 1
		v.ai4 = 0
		
		v.animationFrame = data._settings.angle
		local angledetectionh = 0
		local angledetectionv = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--Execute main AI. This template just jumps when it touches the ground.
	if table.icontains(horizontalframeleft,v.animationFrame) then
		angledetectionh = v.x - 17
	elseif table.icontains(horizontalframeright,v.animationFrame) then
		angledetectionh = v.x + v.width + 1
	else
		angledetectionh = v.x + 9
	end
	
	if table.icontains(verticalframeup,v.animationFrame) then
		angledetectionv = v.y - 16 - 1
	elseif table.icontains(verticalframedown,v.animationFrame) then
		angledetectionv = v.y + v.height + 1
	else
		angledetectionv = v.y + 8
	end
	
	if v.dontMove == false then
		v.ai1 = v.ai1 + 1
	else
		v.ai4 = v.ai4 + 1
		if v.ai4 == sampleNPCSettings.rotationSpeed then
			v.ai3 = 1
			v.ai4 = 0
		end
	end
	
	if v.ai1 == sampleNPCSettings.rotationSpeed then
		v.ai1 = 0
		v.animationTimer = 100
		v.ai3 = 1
	else
		v.animationTimer = 1
	end
	
	local blockdetecter = Colliders.Box(angledetectionh, angledetectionv, 16, 16)
	
	v.ai2 = math.random(0, 25)
	
	if v.ai2 == 25 and v.ai3 == 1 then
		x = NPC.spawn(752, angledetectionh, angledetectionv)
		x.animationFrame = v.animationFrame
		v.ai3 = 0
	end
	
	for _,w in ipairs(Block.getIntersecting(blockdetecter.x, blockdetecter.y, blockdetecter.x + 16, blockdetecter.y + 16)) do
		if Block.SOLID_MAP[w.id] or Block.PLAYERSOLID_MAP[w.id] or Block.SLOPE_MAP[w.id] then
			if not w.isHidden then
				if v.direction == -1 then
					if v.animationFrame == 7 then
						v.animationFrame = 1
					else
						v.animationFrame = v.animationFrame + 2
					end
				else
					if v.animationFrame == 1 then
						v.animationFrame = 7
					else
						v.animationFrame = v.animationFrame - 2
					end
				end
				v.direction = v.direction * -1
				blockdetecter = nil
			end
		end
	end
end

function sampleNPC.onDrawNPC(v)
	if v.despawnTimer <= 0 then
		return
	end
	
	utils.drawNPC(v, {priority = -75})
	utils.hideNPC(v)
end

--Gotta return the library table!
return sampleNPC