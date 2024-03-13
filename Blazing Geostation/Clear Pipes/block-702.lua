--Blockmanager is required for setting basic Block properties
local blockManager = require("blockManager")

--Create the library table
local sampleBlock = {}
--BLOCK_ID is dynamic based on the name of the library file
local blockID = BLOCK_ID

--Register events
function sampleBlock.onInitAPI()
	blockManager.registerEvent(blockID, sampleBlock, "onDrawBlock")
end

local gfx = Graphics.loadImageResolved("right_bits.png")

function sampleBlock.onDrawBlock(v)
	--Don't act during time freeze
	
	if v.id ~= blockID then return end
	
	if Defines.levelFreeze then return end

	local data = v.data
	
	data.img = data.img or Sprite{texture = gfx, frames = 1}

	data.img.position = vector(v.x, v.y - 4)
	
	data.img:draw{sceneCoords = true, frame = 1, priority = -65}
end

--Gotta return the library table!
return sampleBlock