local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")
local voltBlock = {}

local STATE = {
    INACTIVE = 0,
    WARNING = 1,
    ACTIVE = 2,
}

voltBlock.idList = {}
voltBlock.idMap = {}

voltBlock.STATE = STATE

local hittableNPCs = table.iclone(NPC.HITTABLE)
local blacklistedNPCs = {}

local loopShader = Shader()
loopShader:compileFromFile(nil, Misc.resolveFile("sh_loop.frag"))

local function npcFilter(v)
	return (
        not blacklistedNPCs[v.id]
        and not v.isHidden
        and not v.friendly
        and not v.isGenerator
    )
end

local function parseText(txt, data, field)
    local func, err = loadstring("return {"..txt.."}")

    if func == nil then
        error("Couldn't parse the volt block's indices table.")
    else
        data[field] = table.map(func())
    end
end

local function getAngle(x1, x2, y1, y2)
    return math.deg(math.atan2(y1 - y2, x1 - x2))
end

function voltBlock.onInitAPI()
	registerCustomEvent(voltBlock, "onNPCHitByElectricity")
end

function voltBlock.register(id, typ)
    if voltBlock.idMap[id] then return end

    local config = Block.config[id]
    
    blockManager.registerEvent(id, voltBlock, "onTickBlock")
    blockManager.registerEvent(id, voltBlock, "onDrawBlock")

    table.insert(voltBlock.idList, id)
    voltBlock.idMap[id] = typ
end

function voltBlock.whitelistNPC(id)
    if not NPC.HITTABLE_MAP[id] then
        table.insert(hittableNPCs, id)
    end

    blacklistedNPCs[id] = nil
end

function voltBlock.blacklistNPC(id)
    blacklistedNPCs[id] = true
end

-- function to check if a lightning collider touches the given object, you can provide a specific block to check to make the process faster
function voltBlock.touchesThis(obj, v)
    if v then
        for k, b in ipairs(v.data.colliders) do
            if Colliders.collide(b, obj) then
                return true
            end
        end
    else
        for _, v in Block.iterate(voltBlock.idList) do
            for k, b in ipairs(v.data.colliders) do
                if Colliders.collide(b, obj) then
                    return true
                end
            end
        end
    end

    return false
end

function voltBlock.activate(v)
    local data = v.data
    local found = false
    local colT, blockT = {}, {}
    local section = blockutils.getBlockSection(v)

    for k, b in Block.iterate(v.id) do
        if b ~= v and not b.isHidden and not b:mem(0x5A, FIELD_BOOL) and blockutils.getBlockSection(b) == section and data.indices[b.data._settings.idx] then
            local x1 = b.x + b.width/2
            local y1 = b.y + b.height/2

            local x2 = v.x + v.width/2
            local y2 = v.y + v.height/2

            local col = Colliders.Rect(
                (x1 + x2)/2,
                (y1 + y2)/2,
                math.sqrt((x1 - x2)^2 + (y1 - y2)^2) - b.width,
                Block.config[v.id].electricThickness,
                getAngle(x1, x2, y1, y2)
            )

            --col:debug(true)

            b.data.state = STATE.WARNING
            b.data.duration = data._settings.duration
            b.data.electricTimer = 0
            
            table.insert(blockT, b)
            table.insert(colT, col)
            found = true
        end
    end

    if found then
        data.state = STATE.WARNING
        data.electricTimer = 0
        data.colliders = colT
        data.blocks = blockT
        data.duration = data._settings.duration
    end

    data.triggerTimer = 0
end

function voltBlock.onTickBlock(v)
    local data = v.data
    local settings = data._settings
    local config = Block.config[v.id]

    if not data.initialized then
        settings.indices = settings.indices or ""
        settings.indicesToTrigger = settings.indicesToTrigger or ""
        settings.idx = settings.idx or 1
        settings.duration = settings.duration or 64
        settings.triggerDelay = settings.triggerDelay or 80

        parseText(settings.indices, data, "indices")
        parseText(settings.indicesToTrigger, data, "indicesToTrigger")

        data.duration = settings.duration
        data.colliders = {}
        data.blocks = {}
        data.iconFrame = 0
        data.electricFrame = 0
        data.sparkFrame = 0
        data.electricTimer = 0
        data.frameTimer = 0
        data.state = STATE.INACTIVE
        data.triggerTimer = -1
        data.initialized = true

        if settings.startActive then
            voltBlock.activate(v)
        end
    end

    data.frameTimer = data.frameTimer + 1
    data.electricTimer = data.electricTimer + 1

    data.sparkFrame = math.floor(data.frameTimer / config.sparkFramespeed) % config.sparkFrames
    data.electricFrame = math.floor(data.frameTimer / config.electricFramespeed) % config.electricFrames
    data.iconFrame = math.floor(data.frameTimer / config.iconFramespeed) % config.iconFrames

    data.iconFrame = data.iconFrame + config.iconFrames * data.state

    if data.triggerTimer >= settings.triggerDelay + config.warnFrames then
        local section = blockutils.getBlockSection(v)

        for k, b in Block.iterate(v.id) do
            if b ~= v and not b.isHidden and not b:mem(0x5A, FIELD_BOOL) and blockutils.getBlockSection(b) == section and data.indicesToTrigger[b.data._settings.idx] then
                voltBlock.activate(b)
            end
        end

        data.triggerTimer = -1

    elseif data.triggerTimer >= 0 then
        data.triggerTimer = data.triggerTimer + 1
    end

    if data.state == STATE.INACTIVE then
        -- nothing
    elseif data.state == STATE.WARNING and data.electricTimer == config.warnFrames then
        data.state = STATE.ACTIVE
        data.electricTimer = 0

        for k, b in ipairs(data.blocks) do
            if b.isValid then
                b.data.state = STATE.ACTIVE
                b.data.electricTimer = 0
            end
        end

        local sfx = config.activateSFX

        if sfx.id then
            SFX.play(sfx.id, sfx.volume)
        end

    elseif data.state == STATE.ACTIVE then
        for k, b in ipairs(data.colliders) do
            for _, p in ipairs(Player.get()) do
                if Colliders.collide(p, b) and p.forcedState == 0 then
                    p:harm()
                end
            end

            if config.hurtNPCs then
                for _, n in ipairs(Colliders.getColliding{a = b, b = hittableNPCs, btype = Colliders.NPC, filter = npcFilter}) do
                    local eventObj = {cancelled = false}

                    -- event object, npc, block, collider
                    voltBlock.onNPCHitByElectricity(eventObj, n, v, b)
                    
                    if not eventObj.cancelled then
                        n:harm(HARM_TYPE_NPC)
                    end
                end
            end
        end

        if data.electricTimer == data.duration then
            data.state = STATE.INACTIVE
            data.electricTimer = 0
            data.colliders = {}
            data.blocks = {}
            data.duration = settings.duration
        end
    end
end

function voltBlock.onDrawBlock(v)
    local data = v.data
    local config = Block.config[v.id]

    if not data.initialized then return end

    -- lightning icon
    local img = config.iconImage

    local gfxwidth = img.width
    local gfxheight = img.height/(config.iconFrames * 3) -- multiplied by 3 because there are 3 states for the block

    Graphics.drawImageToSceneWP(
        img,
        v.x + v.width/2 - gfxwidth/2,
        v.y + v.height/2 - gfxheight/2,
        0, data.iconFrame * gfxheight,
        gfxwidth, gfxheight,
        config.iconPriority
    )

    local elecImg = config.electricImages[data.state]
    local sparkImg = config.sparkImage

    -- electricity and spark
    for k, col in ipairs(data.colliders) do
        local b = data.blocks[k]

        col.rotation = getAngle(b.x + b.width/2, v.x + v.width/2, b.y + b.height/2, v.y + v.height/2)

        if sparkImg and data.state == STATE.ACTIVE then
            local gfxwidth = sparkImg.width
            local gfxheight = sparkImg.height/config.sparkFrames

            for i = -1, 1, 2 do
                local angle = col.rotation + 90 - i * 90    
                local xOffset = col.width/2 * math.cos(math.rad(angle))
                local yOffset = col.width/2 * math.sin(math.rad(angle))

                Graphics.drawImageToSceneWP(
                    sparkImg,
                    col.x - gfxwidth/2 + xOffset,
                    col.y - gfxheight/2 + yOffset,
                    0, data.sparkFrame * gfxheight,
                    gfxwidth, gfxheight,
                    config.sparkPriority
                )
            end
        end

        if elecImg then
            local gfxwidth = elecImg.width
            local gfxheight = elecImg.height/config.electricFrames

            Graphics.drawBox{
                texture = elecImg,
                x = col.x,
                y = col.y,

                sourceY = data.electricFrame * gfxheight,
                sourceWidth = col.width,
                sourceHeight = gfxheight,

                centered = true,
                sceneCoords = true,
                shader = loopShader,
                priority = config.electricPriority or -65.1,
                rotation = col.rotation,
            }
        end
    end
end

return voltBlock