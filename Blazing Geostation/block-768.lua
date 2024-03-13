local blockManager = require("blockManager")
local AI = require("AI/voltBlock")

local sampleBlock = {}
local blockID = BLOCK_ID

local sampleBlockSettings = {
	id = blockID,

	frames = 1,
	framespeed = 8,

	electricThickness = 16,
	warnFrames = 32,
	activateSFX = {id = "MM1-ElecZap.ogg", volume = 0.6},

	iconFrames = 1, -- per-state frames
	iconFramespeed = 8,
	iconPriority = -65,
	iconImage = Graphics.loadImageResolved("block-"..blockID.."-icon.png"),

	electricFrames = 3,
	electricFramespeed = 4,	
	electricPriority = -65.1,
	electricImages = {
		[AI.STATE.WARNING] = Graphics.loadImageResolved("block-"..blockID.."-electricity-warn.png"),
		[AI.STATE.ACTIVE]  = Graphics.loadImageResolved("block-"..blockID.."-electricity-main.png"),
	},

	sparkFrames = 2,
	sparkFramespeed = 4,
	sparkPriority = -65,
	sparkImage = Graphics.loadImageResolved("block-"..blockID.."-spark.png"),

	hurtNPCs = false, -- this can be performance costly so it is false by default
}

blockManager.setBlockSettings(sampleBlockSettings)
AI.register(blockID)

return sampleBlock