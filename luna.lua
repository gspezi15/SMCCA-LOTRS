--------------------------------------------------
-- Episode code for every level
-- Created 23:28 2021-2-7
--------------------------------------------------

local aw = require("anotherwalljump")
aw.registerAllPlayersDefault()
local areaNames = require("areaNames")
local warpTransition = require ("warpTransition")
local littleDialogue = require("littleDialogue")
littleDialogue.defaultStyleName = "ml"

local SmgLifeSystem = require("SmgLifeSystem")
SmgLifeSystem.healthX = 650
SmgLifeSystem.healthY = 10

local kindhurtblock = require ("kindhurtblock")


-- Run code on the first frame
function onStart()
    --Your code here
end

-- Run code every frame (~1/65 second)
-- (code will be executed before game logic will be processed)
function onTick()
    --Your code here
end

-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(eventName)
    --Your code here
end


