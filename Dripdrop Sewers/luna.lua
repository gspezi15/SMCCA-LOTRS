local areaNames = require("areanames")
local SmgLifeSystem = require("SmgLifeSystem")
SmgLifeSystem.healthX = 650
SmgLifeSystem.healthY = 10


--Change this in your lua file to have automatically appearing messages on section switch for specific sections:
areaNames.sectionNames = {
	[0] = "Dripdrop Sewers",
        [1] = "Secret Area",
		[2] = "Secret Area",
        [3] = "Tunnel to Mainframe",
        [4] = "Cyberspace",
        [5] = "Clear-Pipe Maze",
        [6] = "End",
        [7] = "Meadow Highlands",
        [8] = "Secret Area",
        [9] = "",
        [10] = "",
        [11] = "",
        [12] = "",
        [13] = "",
        [14] = "",
        [15] = "",
        [16] = "",
        [17] = "",
        [18] = "",
        [19] = "",
        [20] = ""
}

function onLoadSection0()
	SmgLifeSystem.AirMeterActive = true
end

function onLoadSection3()
	SmgLifeSystem.AirMeterActive = true
end

function onLoadSection5()
	SmgLifeSystem.AirMeterActive = true
end
