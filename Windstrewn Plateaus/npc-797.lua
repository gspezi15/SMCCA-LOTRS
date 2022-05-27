local npc = {}
local npcManager = require("npcManager")

local id = NPC_ID

npcManager.setNpcSettings({
	id = id,
	
	jumphurt = true,
	nohurt = true,
	
	noyoshi = true,
	noiceball = true,
	
	effect = 768,
})

local sfx =  SFX.play("wind.ogg", 1, 0)
sfx:pause()
		
function npc.onTickEnd()
	local play = false
	
	for k,v in NPC.iterate(id) do
		if v.isValid and v.despawnTimer > 100 then
			play = true
		end
	end
	
	if play then
		sfx:resume()
	else
		sfx:pause()
	end
end

local function isColliding(a,b)
	   if ((b.x >= a.x + a.width) or
		   (b.x + b.width <= a.x) or
		   (b.y >= a.y + a.height) or
		   (b.y + b.height <= a.y)) then
			  return false 
	   else return true
           end
	end
	
function npc.onTickEndNPC(v)
	if v.despawnTimer < 100 then
		return 
	end
	
	v.friendly = true
	
	local config = NPC.config[id]
	local section = Section(v.section)
	local bound = section.boundary
	
	if math.random() > 0.5 then
		for k,c in ipairs(Camera.get()) do
			if ((k == 2 and c.isSplit) or k ~= 2) and isColliding(c, {
				x = bound.left, 
				y = bound.top,
				width = bound.right - bound.left, 
				height = bound.bottom - bound.top,
			}) then
				local x = c.x
			
				if v.direction == -1 then
					x = c.x + c.width
				end
				
				local e = Effect.spawn(config.effect, x, c.y)
				e.y = e.y + (math.random(c.height))
				e.speedX = 48 * v.direction
			end
		end
	end
	
	for k,p in ipairs(Player.get()) do
		if p.section == v.section then
			if v.direction == -1 then
				p.speedX = math.clamp(p.speedX, -6, 2)
				
				if not p.keys.right then
					p:mem(0x138, FIELD_FLOAT, 0.25 * v.direction)
				end
			else
				p.speedX = math.clamp(p.speedX, -2, 6)
			
				if not p.keys.left then
					p:mem(0x138, FIELD_FLOAT, 0.25 * v.direction)
				end
			end
		end
	end
end

function npc.onInitAPI()
	registerEvent(npc, 'onTickEnd')
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
end

return npc