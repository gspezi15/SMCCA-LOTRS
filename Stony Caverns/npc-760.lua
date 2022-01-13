local smwfuzzy = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.HITTABLE})

-- settings
local config = {
	id = npcID, 
	gfxoffsety = 0, 
	width = 60, 
    height = 60,
    gfxwidth = 96,
    gfxheight = 64,
    frames = 3,
    framestyle = 1,
    noiceball = false,
    nofireball = false,
    noyoshi = true,
	noblockcollision = true,
    jumphurt = false,
    spinjumpSafe = true,
    nogravity = true,

    maxrange = 144,
    minrange = 32,
    shockframes = 2,
    shocktimer = 64,
    health = 3,
    fallingid = 761,
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

function smwfuzzy.onInitAPI()
    npcManager.registerEvent(npcID, smwfuzzy, "onTickEndNPC")
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

function smwfuzzy.onTickEndNPC(v)
    if Defines.levelFreeze then return end

    if v:mem(0x12A, FIELD_WORD) <= 0 then
        v.data.active = nil
        return
    end

    if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x138, FIELD_WORD) > 0 then
        v.data.active = nil
        v.animationFrame = 0
        if v.direction == 1 and NPC.config[v.id].framestyle >= 1 then
            v.animationFrame = v.animationFrame + NPC.config[v.id].frames
        end
        return
    end

    if v.data.active == nil then
        v.data.active = false
        v.data.timer = nil
    end
    local cfg = NPC.config[v.id]
    
    if not v.data.active then
        local cx, cy = v.x + 0.5 * v.width, v.y + 0.5 * v.height
        local p = Player.getNearest(cx, cy)
        local min, max = math.abs(cfg.minrange), math.abs(cfg.maxrange)
        if min > max then
            max, min = min, max
        end
        local leftBound = cx + (0.5 * v.width + min) * v.direction
        local rightBound = leftBound + max * v.direction
        if rightBound < leftBound then
            leftBound, rightBound = rightBound, leftBound
        end
        if player.x + player.width > leftBound and player.x < rightBound then
            v.data.active = true
            v.data.timer = 0
        end
        v.animationFrame = 0
    else
        v.data.timer = v.data.timer + 1 
        if v.data.timer >= cfg.shocktimer then
            v:transform(cfg.fallingID)
        end
        v.animationFrame = 1 + (math.floor(v.data.timer/cfg.framespeed) % cfg.shockframes)
    end

    if v.direction == 1 and cfg.framestyle >= 1 then
        v.animationFrame = v.animationFrame + cfg.frames
    end
end

return smwfuzzy