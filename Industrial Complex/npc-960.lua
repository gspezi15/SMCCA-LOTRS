local smwfuzzy = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.HITTABLE})

-- settings
local config = {
	id = npcID, 
	width = 38, 
    height = 22,
    gfxwidth = 64,
    gfxheight = 32,
    frames = 2,
	framestyle = 1,
    nogravity = true,
    spinjumpsafe = false,
    noblockcollision = true,
	jumphurt = true,
    score = 0
}
npcManager.setNpcSettings(config)

function smwfuzzy.onInitAPI()
	npcManager.registerEvent(npcID, smwfuzzy, "onTickEndNPC")
end

function smwfuzzy.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	local data = v.data
	v.animationFrame = v.ai1
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = config.frames
	});
	
end

return smwfuzzy