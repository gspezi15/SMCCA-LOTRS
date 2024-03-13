local blockmanager = require("blockmanager")

local blockID = BLOCK_ID

local block = {}

--Register events
function block.onInitAPI()
	blockmanager.registerEvent(blockID, block, "onDrawBlock")
end

local gfx = Graphics.loadImageResolved("pipe_bits.png")

function block.onDrawBlock(v)
	--Don't act during time freeze
	
	if v.id ~= blockID then return end
	
	if Defines.levelFreeze then return end

	local data = v.data
	
	data.img = data.img or Sprite{texture = gfx, frames = 1}

	data.img.position = vector(v.x - 16, v.y)
	
	data.img:draw{sceneCoords = true, frame = 1, priority = -65}
end

return block