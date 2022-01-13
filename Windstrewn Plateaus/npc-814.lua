local npcManager = require("npcManager")
local npc = {}
local id = NPC_ID

npcManager.setNpcSettings({
	id = id,
	
	frames = 6,
	framespeed = 4,
	
	jumphurt = true,
	nohurt = true,
	
	windheight = 96,
})

function npc.onInitAPI()
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
end

local function hover(v, n)
	if (NPC.config[n.id].iscoin and n.ai1 <= 0) or n.isHidden then
		return
	end
	
	n.speedY = n.speedY - 0.65
end

local thwomps = {
	[437] = true,
	[295] = true,
	[435] = true,
	[432] = true,
	
	[423] = true,
	[424] = true,
}

function npc.onTickEndNPC(v)
	local config = NPC.config[id]
	
	for k,n in NPC.iterateIntersecting(v.x, v.y, v.x + v.width, v.y + v.height) do
		if thwomps[n.id] and n.speedY > 0 and not n.friendly then
			Effect.spawn(772, v.x, v.y)
			
			v:kill(2)
		end
	end
	
	for k,n in NPC.iterateIntersecting(v.x, v.y - config.windheight, v.x + v.width, v.y + v.height) do
		if n.id ~= id then
			hover(v, n)
		end
	end
	
	for k,n in ipairs(Player.getIntersecting(v.x, v.y - config.windheight, v.x + v.width, v.y + v.height)) do
		n.speedY = n.speedY - 1
	end
	
	if math.random() > 0.5 then
		local e = Effect.spawn(773, v.x + v.width / 2 - 4, v.y - 4)
		e.speedY = -6
	end
	
	v.speedX = 1 * v.direction
end

return npc