--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local wildPiranhaStalk = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local wildPiranhaStalkSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 2,
	framestyle = 2,
	framespeed = 8,
	speed = 1,
	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false,
	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(wildPiranhaStalkSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
	}, 
	{
	}
);

--Custom local definitions below
local STATE_DORMANT = 0
local STATE_ACTIVE = 1

--Register events
function wildPiranhaStalk.onInitAPI()
	npcManager.registerEvent(npcID, wildPiranhaStalk, "onTickNPC")
	npcManager.registerEvent(npcID, wildPiranhaStalk, "onDrawNPC")
end

function wildPiranhaStalk.onDrawNPC(v)
	local f = v.data.state or 0
	
	local dir = v.data.renderdir or 0
	
	if dir==1 then
		f = f+2
	end
	
	--Upside Down
	if v.data.isceiling then
		f = f+4
	end

	v.animationFrame = f
end

function wildPiranhaStalk.onTickNPC(v)
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
		data.renderdir = 0 --render direction, different from actual direction
		
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
	if data.myhead.isValid then
		data.renderdir = data.myhead.direction
	end
	
	if not Layer.isPaused() and v.layerObj then
		v.speedX = v.layerObj.speedX
		v.speedY = v.layerObj.speedY
	else
		v.speedX = 0
		v.speedY = 0
	end
	
end

--Gotta return the library table!
return wildPiranhaStalk