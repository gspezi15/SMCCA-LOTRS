--Blockmanager is required for setting basic Block properties
local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")

--Create the library table
local sampleBlock = {}
--BLOCK_ID is dynamic based on the name of the library file
local blockID = BLOCK_ID


--Register events
function sampleBlock.onInitAPI()
	blockManager.registerEvent(blockID, sampleBlock, "onTickEndBlock")
	blockManager.registerEvent(blockID, sampleBlock, "onCollideBlock")
end


function sampleBlock.onCollideBlock(block,hitter)
	if type(hitter) == "Player" then
		hitter:harm()
	end
end



function sampleBlock.onTickEndBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data
	
	if lunatime.tick() % 16 < 8 then
		blockutils.setBlockFrame(blockID, 0)
	elseif lunatime.tick() % 16 < 16 then
		blockutils.setBlockFrame(blockID, 2)
	end
end

--Gotta return the library table!
return sampleBlock