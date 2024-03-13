local blockmanager = require("blockmanager")
local cp = require("blocks/ai/clearpipe")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	noshadows = true,
	width = 32,
	height = 64
})

-- Up, down, left, right
cp.registerPipe(blockID, "END", "HORZ", {false, false, true,  true})

--Register events
function block.onInitAPI()
	blockmanager.registerEvent(blockID, block, "onDrawBlock")
end

local gfx = Graphics.loadImageResolved("left_bits.png")

function block.onDrawBlock(v)
	--Don't act during time freeze
	
	if v.id ~= blockID then return end
	
	if Defines.levelFreeze then return end

	local data = v.data
	
	data.img = data.img or Sprite{texture = gfx, frames = 1}

	data.img.position = vector(v.x, v.y - 4)
	
	data.img:draw{sceneCoords = true, frame = 1, priority = -65}
end


return block