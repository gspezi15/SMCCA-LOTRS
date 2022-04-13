local npc = {}
local id = NPC_ID

local npcManager = require "npcManager"

npcManager.setNpcSettings{
	id = id,
	
	framestyle = 1,
	frames=2,
	
	width = 32,
	height = 64,
	gfxwidth = 32,
	gfxheight = 64,
	
	jumphurt = true,
	noblockcollision = true,
	nogravity = true,
	
	spinjumpsafe = true,
	
	vspeed = 1.5,
	iceball = id + 1,
}

local function CanComeOut(Loc1, Loc2)
    local tempCanComeOut = true

    if(Loc1.x <= Loc2.x + Loc2.width + 32) then
        if(Loc1.x + Loc1.width >= Loc2.x - 32) then
            if(Loc1.y <= Loc2.y + Loc2.height + 300) then
                if(Loc1.y + Loc1.height >= Loc2.y - 300) then
                    tempCanComeOut = false;
                end
            end
        end
    end
	
    return tempCanComeOut;
end

function npc.onTickEndNPC(v)
	local cfg = NPC.config[id]
	local data = v.data._basegame
	
	--v.ai1 = state
	--v.ai2 = timer
	--ai3 = direction
	--ai4 = player idx
	--ai5 = frame
	
	if not data.init then
		v.y = v.y + v.height
		v.height = 0
		
		data.init = true
	end
	
	v.ai4 = Player.getNearest(v.x + v.width, v.y + v.height).idx
	local p = Player(v.ai4)
	
	v.ai5 = (v.ai3 == 1 and cfg.frames) or 0
	v.animationFrame = -1
	
	if p.x + p.width / 2 > v.x + v.width / 2 then
		v.ai3 = 1
	else
		v.ai3 = -1
	end
	
	if p.y + p.height < v.y + 16 then
		v.ai5 = v.ai5 + 1
	end
	
	if v.ai1 == 0 then
		v.ai2 = v.ai2 + 1
		
		if CanComeOut(v, p) and p.deathTimer <= 0 and v.ai2 >= 150 then
			v.ai1 = 1
			v.ai2 = 0
		end
	elseif v.ai1 == 1 then
		v.height = v.height + cfg.vspeed
		v.y = v.y - cfg.vspeed
		
		if v.height >= cfg.height then
			v.height = cfg.height
			v.ai1 = 2
		end
	elseif v.ai1 == 2 then
		v.ai2 = v.ai2 + 1
		
		if v.ai2 == 50 then
			local ice = NPC.spawn(cfg.iceball, v.x, v.y)
			ice.despawnTimer = 100
			ice.direction = v.ai3
			ice.animationFrame = 1
			
			if ice.width == 16 then
				ice.x = v.x + 8
				ice.y = v.y + 8
			else
				ice.x = v.x
				ice.y = v.y
			end
			
			ice.speedX = 3 * ice.direction
			
			local c = (v.x + v.width / 2) - (p.x + p.width / 2)
			local d = (v.y + v.height / 2) - (p.y + p.height / 2)
			
			if c == 0 then
				c = -0.1
			end
			
			ice.speedY = (d / c) * ice.speedX
			ice.speedY = math.clamp(ice.speedY, -2, 2)
			ice.layerName = "Spawned NPCs"
			ice.friendly = v.friendly
		elseif v.ai2 >= 100 then
			v.ai1 = 3
			v.ai2 = 0
		end
	elseif v.ai1 == 3 then
		v.height = v.height - cfg.vspeed
		v.y = v.y + cfg.vspeed
		
		if v.height <= 0 then
			v.height = 0
			v.ai1 = 0
		end
	end
	
	if v.height == 0 then
		v:mem(0x156, FIELD_WORD, 100)
	else
		v:mem(0x156, FIELD_WORD, 0)
	end
end

function npc.onCameraDrawNPC(v)
	if v.despawnTimer <= 0 then return end
	
	local texture = Graphics.sprites.npc[id].img
	local cfg = NPC.config[id]
	
	Graphics.drawImageToSceneWP(
		texture,
		v.x + cfg.gfxoffsetx,
		v.y + cfg.gfxoffsety,
		0,
		v.ai5 * cfg.height,
		v.width,
		v.height,
		-45
	)
	
	-- Graphics.drawBox{
		-- x = v.x,
		-- y = v.y,
		-- width = v.width,
		-- height = v.height,
		
		-- sceneCoords = true,
		-- color = Color.red .. 0.5,
	-- }
end

function npc.onInitAPI()
	npcManager.registerHarmTypes(id,
		{
			HARM_TYPE_NPC,
			HARM_TYPE_HELD,
			HARM_TYPE_TAIL,
			HARM_TYPE_SWORD,
		},
		{
			[HARM_TYPE_NPC]=10,
			[HARM_TYPE_HELD]=10,
			[HARM_TYPE_TAIL]=10,
		}
	)
	
	npcManager.registerEvent(id, npc, 'onCameraDrawNPC')
	npcManager.registerEvent(id, npc, 'onTickNPC')	
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
end

return npc