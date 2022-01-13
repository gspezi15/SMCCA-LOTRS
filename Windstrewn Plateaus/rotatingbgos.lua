local bg = {}

function bg.onInitAPI()
    registerEvent(bg, "onDraw")
end

local images = {}

local tableinsert = table.insert

function bg.onDraw()
    local drawnBGOs = {}
    local drawnBGOIDs = {}

    local rt = lunatime.tick()

    for k,v in ipairs(BGO.getIntersecting(camera.x - 300, camera.y - 300, camera.x + 1100, camera.y + 900)) do
        if BGO.config[v.id].customrotation then
            if drawnBGOs[v.id] == nil then
                drawnBGOs[v.id] = {vt = {}, tx = {}}
                tableinsert(drawnBGOIDs, v.id)
                images[v.id] = images[v.id] or Graphics.loadImage(Misc.resolveFile("background-" .. v.id .. "r.png"))
            end
            local img = images[v.id]
            local rotationTimer = rt * BGO.config[v.id].customrotation
            local w = img.width * 0.5
            local vt = {
                vector(-w, -w):rotate(rotationTimer),
                vector(w, -w):rotate(rotationTimer),
                vector(-w, w):rotate(rotationTimer),
                vector(w, w):rotate(rotationTimer),
            }

            local x, y = v.x + 0.5 * v.width, v.y + 0.5 * v.height
            tableinsert(drawnBGOs[v.id].vt, x + vt[1].x)
            tableinsert(drawnBGOs[v.id].vt, y + vt[1].y)
            tableinsert(drawnBGOs[v.id].tx, 0)
            tableinsert(drawnBGOs[v.id].tx, 0)
            for i=1, 2 do
                tableinsert(drawnBGOs[v.id].vt, x + vt[2].x)
                tableinsert(drawnBGOs[v.id].vt, y + vt[2].y)
                tableinsert(drawnBGOs[v.id].tx, 1)
                tableinsert(drawnBGOs[v.id].tx, 0)
                tableinsert(drawnBGOs[v.id].vt, x + vt[3].x)
                tableinsert(drawnBGOs[v.id].vt, y + vt[3].y)
                tableinsert(drawnBGOs[v.id].tx, 0)
                tableinsert(drawnBGOs[v.id].tx, 1)
            end
            tableinsert(drawnBGOs[v.id].vt, x + vt[4].x)
            tableinsert(drawnBGOs[v.id].vt, y + vt[4].y)
            tableinsert(drawnBGOs[v.id].tx, 1)
            tableinsert(drawnBGOs[v.id].tx, 1)
        end
    end

    for k,v in ipairs(drawnBGOIDs) do
        Graphics.glDraw{
            texture = images[v],
            vertexCoords = drawnBGOs[v].vt,
            textureCoords = drawnBGOs[v].tx,
            priority = BGO.config[v].priority or -75,
            primitive = Graphics.G_TRIANGLES,
            sceneCoords = true
        }
    end
end

return bg