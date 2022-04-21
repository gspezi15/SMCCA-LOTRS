local blockmanager = require("blockmanager")

local blockID = BLOCK_ID

local block = {}

local blockSettings = {
	id = blockID,
	customhurt = true
}

blockmanager.setBlockSettings(blockSettings)

function block.onInitAPI()
	blockmanager.registerEvent(blockID, block, "onCollideBlock")
end

function block.onCollideBlock(v,p)
	if type(p) == "Player" then
		if v.y <= p.y then
			p:harm()
		end
	end
end

return block