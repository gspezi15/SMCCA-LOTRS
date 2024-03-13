local blockmanager = require("blockmanager")
local cp = require("blocks/ai/clearpipe")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	noshadows = true,
	width = 64,
	height = 32
})

--Register events
function block.onInitAPI()
	blockmanager.registerEvent(blockID, block, "onDrawBlock")
end

local gfx = Graphics.loadImageResolved("down_bits.png")

function block.onDrawBlock(v)
	--Don't act during time freeze
	
	if v.id ~= blockID then return end
	
	if Defines.levelFreeze then return end

	local data = v.data
	
	data.img = data.img or Sprite{texture = gfx, frames = 1}

	data.img.position = vector(v.x - 4, v.y)
	
	data.img:draw{sceneCoords = true, frame = 1, priority = -65}
end

-- Up, down, left, right
cp.registerPipe(blockID, "END", "VERT", {true,  true,  false, false})

return block