local SmgLifeSystem = require("SmgLifeSystem")
SmgLifeSystem.healthX = 650
SmgLifeSystem.healthY = 10

function onLoadSection0()
	SmgLifeSystem.daredevilActive = false
	SmgLifeSystem.AirMeterActive = true
end

function onLoadSection1()
	SmgLifeSystem.daredevilActive = true
	SmgLifeSystem.AirMeterActive = false
end