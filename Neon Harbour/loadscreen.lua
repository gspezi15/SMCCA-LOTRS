package.path = package.path .. ";./scripts/?.lua"
local rng = require("base/rng")

local imgtable = ("Blossom Megalopolis.png")
local animationtest = Graphics.loadImage("loadingscreen/animationtest.png")

local selecter = rng.randomInt(1,#imgtable)
local randomimage = Graphics.loadImage(mem(0x00B2C61C, FIELD_STRING).."loadingscreen/"..imgtable[selecter]);

local myFrames = 6 --frames
local animationframespeed = 8 --Change this to framespeed
local animationTimer = 0
function onDraw()
    animationTimer = animationTimer + 1
    local animationframes =  math.floor(animationTimer / animationframespeed) % myFrames
    Graphics.drawImage(randomimage, 380, 400)
    Graphics.drawImage(animationtest, 0, 0, 0, animationframes * 64, 128, 64)
end