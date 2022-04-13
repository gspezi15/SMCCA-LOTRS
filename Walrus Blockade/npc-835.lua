local npc = {}
local id = NPC_ID

local npcManager = require "npcManager"

npcManager.setNpcSettings{
	id = id,
	
	frames = 4,
	framestyle = 0,
	framespeed = 4,
	
	width = 16,
	height=16,
	gfxwidth=16,
	gfxheight=16,
	
	jumphurt = true,
	nohurt = true,
	
	isinteractable = true,
	noiceball = true,
	
	nogravity = true,
	noblockcollision = true,
}

function npc.onNPCKill(e, v, r)
	if v.id ~= id then return end

	if r == 9 then
		for k,p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
			if p.forcedState == 0 and p.deathTimer <= 0 and p.BlinkTimer <= 0 and not p.isMega and not p.hasStarman then
				p.keys.run = false
				
				local n = NPC.spawn(263, p.x, p.y)
				n.ai1 = -p.idx
				n.direction = -p.direction
				n.speedX = 6 * n.direction
				n.friendly = v.friendly
				
				Effect.spawn(10, p.x, p.y)
			else
				e.cancelled = true
			end
		end
	end
end

function npc.onTickEndNPC(v)
	if math.random() > 0.5 then
		Effect.spawn(80, v.x + math.random(0, v.width), v.y + math.random(0, v.height))
	end
	
	if v.friendly then
		for k,p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
			v:kill(9)
		end
	end
end

function npc.onInitAPI()
	registerEvent(npc, 'onNPCKill')
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
end

return npc