local shockplatforms = {}

local blockutils = require("blocks/blockutils")
local blockmanager = require("blockmanager")

shockplatforms.shockableIDMap = {}

shockplatforms.shockerIDs = {}
shockplatforms.shockerIDMap = {}


function shockplatforms.registerShockable(id)
	shockplatforms.shockableIDMap[id] = true
	blockmanager.registerEvent(id, shockplatforms, "onTickBlock")
end

-- Default registers
shockplatforms.registerShockable(751)
shockplatforms.registerShockable(753)

function shockplatforms.registerShocker(id, block)
	table.insert(shockplatforms.shockerIDs, block)
	shockplatforms.shockerIDMap[block] = id
end

function shockplatforms.onTickBlock(v)
	if v.data.timer == nil then
		v.data.timer = 0
	end 
	if v.data.timer <= 0 then return end
	v.data.timer = v.data.timer - 1
end

function shockplatforms.onStart()
	local secs = Section.get()
	for k,v in ipairs(Block.get(shockplatforms.shockerIDs)) do
		local s = 0
		for k,sb in ipairs(secs) do
			local b = sb.boundary
			if b.left < v.x and b.right > v.x + v.width and b.top < v.y and b.bottom > v.y + v.height then
				s = k-1
				break
			end
		end
		NPC.spawn(shockplatforms.shockerIDMap[v.id], v.x + 0.5 * v.width, v.y + 0.5 * v.height, s, true, true)
	end
end

function shockplatforms.onInitAPI()
    registerEvent(shockplatforms, "onStart")
end

return shockplatforms