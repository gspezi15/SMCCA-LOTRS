local smwfuzzy = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.HITTABLE})

-- settings
local config = {
	id = npcID, 
	gfxoffsety = 2, 
	width = 60, 
    height = 60,
    gfxwidth = 64,
    gfxheight = 64,
    frames = 1,
    framestyle = 1,
    noiceball = false,
    nofireball = false,
    noyoshi = true,
	noblockcollision = false,
    jumphurt = false,
    spinjumpSafe = true,
    nogravity = false,

    health = 3,
    earthquakes = 2,
    bounceheight = 8
}

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
		HARM_TYPE_LAVA,
	}, 
	{
		[HARM_TYPE_PROJECTILE_USED]=760,
		[HARM_TYPE_HELD]=760,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
);

npcManager.setNpcSettings(config)

local function findAndRemove(list, obj)
	for k,v in ipairs(list) do
		if v == obj then
			table.remove(list, k)
			break
		end
	end
end

function smwfuzzy.onInitAPI()
    npcManager.registerEvent(npcID, smwfuzzy, "onTickEndNPC")
    npcManager.registerEvent(npcID, smwfuzzy, "onDrawNPC")
    registerEvent(smwfuzzy, "onNPCHarm")
end

function smwfuzzy.onNPCHarm(e, v, r, c)
    if v.id == NPC_ID and r == 3 then
        if c and c.id == 13 then
            local v = pnpc.wrap(v)
            v.data.hp = v.data.hp or NPC.config[npcID].health
            v.data.hp = v.data.hp - 1
            if v.data.hp > 0 then
                e.cancelled = true
            end
            SFX.play(9)
        end
    end
end

local thumpSFX = Misc.resolveFile("bowlingball.ogg") or Misc.resolveFile("sound/extended/bowlingball.ogg")

local function blockFilter(a)
	return not (a.isHidden or a:mem(0x5A, FIELD_WORD) ~= 0 or Block.LAVA_MAP[a.id]);
end

function smwfuzzy.onTickEndNPC(v)
    if Defines.levelFreeze then return end

    if v:mem(0x12A, FIELD_WORD) <= 0 then
        v.data.angle = nil
        return
    end

    if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x138, FIELD_WORD) > 0 then
        v.data.angle = nil
        return
    end

    local data = v.data

    if data.angle == nil then
        data.angle = 0
        data.bounced = false
        data.spdvec = vector.v2(v.speedX, v.speedY);
        data.collider = data.collider or Colliders.Box(v.x, v.y, v.width, v.height + 1)
    end

    -- collision code. run for your life
	data.collider.x = v.x
	data.collider.y = v.y;
	
	local hitAblock,_,blockList = Colliders.collideBlock(data.collider,Colliders.BLOCK_SOLID..Colliders.BLOCK_SEMISOLID..Colliders.BLOCK_HURT..Colliders.BLOCK_PLAYER, blockFilter)
	if not hitAblock then
		local tmpNPCList = NPC.getIntersecting(v.x-1, v.y-1, v.x+v.width+1, v.y+v.height+1)
		for k,n in ipairs(tmpNPCList) do
			if n ~= v.__ref then
				local configFile = NPC.config[n.id]
				if configFile.npcblocktop or configFile.playerblocktop then
					if (not n.isHidden) and n:mem(0x12A, FIELD_WORD) > 0 and n:mem(0x12C, FIELD_WORD) == 0 and n:mem(0x138, FIELD_WORD) == 0 and n:mem(0x64, FIELD_BOOL) == false then
						table.insert(blockList, n)
						hitAblock = true
					end
				end
			end
		end
    end
    
    local cfg = NPC.config[v.id]

    if hitAblock then
		local inNormal = nil;
		local success = nil;
		local pt = vector.v2(v.x+(0.5*v.width),v.y+(0.5*v.height));
		local dir = vector.down2*(v.height*0.5+32);
		repeat
			local p,_,n,o = Colliders.raycast(pt,dir,blockList)
			if not p then
				break
			end
			if (n.x ~= 0 or n.y ~= 0) then 
				inNormal = n; 
				success = p
			else
				findAndRemove(blockList, o);
			end
		until (inNormal ~= nil or #blockList == 0);
				
		if (not success) and #blockList > 0 then
			local success1,pt1,n1,_ = Colliders.raycast(pt-vector.v2(v.width*0.5,0),dir,blockList)
				
			local success2,pt2,n2,_ = Colliders.raycast(pt+vector.v2(v.width*0.5,0),dir,blockList)
				
			success = success1 or success2;
					
			if (success1 and not success2) then
				inNormal = n1;
			elseif (success2 and not success1) then
				inNormal = n2;
			elseif (success1 and success2) then
				if (pt2.y < pt1.y) then
					inNormal = n2;
				else
					inNormal = n1;
				end
			end
		end
				
		if success and (inNormal.x ~= 0 or inNormal.y ~= 0) then
            if not data.bounced then
                data.bounced = true
                data.spdvec.x = 2 * v.direction
                v.speedX = 2 * v.direction
            end
            if cfg.earthquakes > 0 then
                Defines.earthquake = cfg.earthquakes
                SFX.play(thumpSFX)
            end
			local inDirection = data.spdvec
			-- apply vector
            local Result = inDirection - 2 * inDirection:project(inNormal)
					
			local spdvec = vector.v2(math.clamp(Result.x, -3.5, 3.5), -math.abs(cfg.bounceheight))
			v.speedX,v.speedY = spdvec.x,spdvec.y;
		end
    end
    
	data.spdvec.x = v.speedX;
	data.spdvec.y = v.speedY;
    
    if v.speedX ~= 0 then
        v.data.angle = (v.data.angle + v.speedX * 2) % 360
    end
end

function smwfuzzy.onDrawNPC(v)
    if v:mem(0x12A, FIELD_WORD) <= 0 then
        return
    end

    if not v.data.angle then return end

    local cfg = NPC.config[v.id]

    local p = -45
    if cfg.foreground then
        p = -15
    end

    local gfxw, gfxh = cfg.gfxwidth * 0.5, cfg.gfxheight * 0.5

    local vt = {
        vector(-gfxw, -gfxh),
        vector(gfxw, -gfxh),
        vector(gfxw, gfxh),
        vector(-gfxw, gfxh),
    }

    local lowBound = (v.animationFrame) / (cfg.frames * (cfg.framestyle + 1))
    local highBound = (v.animationFrame + 1) / (cfg.frames * (cfg.framestyle + 1))

    local tx = {
        0, lowBound,
        1, lowBound,
        1, highBound,
        0, highBound,
    }

    local x, y = v.x + 0.5 * v.width, v.y + 0.5 * v.height

    for k,a in ipairs(vt) do
        vt[k] = a:rotate(v.data.angle or 0)
    end

    Graphics.glDraw{
        vertexCoords = {
            x + vt[1].x, y + vt[1].y,
            x + vt[2].x, y + vt[2].y,
            x + vt[3].x, y + vt[3].y,
            x + vt[4].x, y + vt[4].y,
        },
        textureCoords = tx,
        primitive = Graphics.GL_TRIANGLE_FAN,
        texture = Graphics.sprites.npc[v.id].img,
        sceneCoords = true,
        priority = p
    }

    npcutils.hideNPC(v)
end

return smwfuzzy