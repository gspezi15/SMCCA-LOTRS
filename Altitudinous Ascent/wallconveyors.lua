local wallcon = {}

local function leftCol()
	return player:mem(0x148, FIELD_WORD) > 0
end
local function rightCol()
	return player:mem(0x14C, FIELD_WORD) > 0
end
local function botCol()
	return player:mem(0x146, FIELD_WORD) > 0
end

local wallCD = 0
local wasColliding = false
local directionLock

-- Frame to display when handing. Externally change if your character needs a different one.
wallcon.hangingFrame = 31

-- Table for facing directions for wall conveyors
local facingTable = {
	[-1] = {ids={}, func=leftCol},
	[1] =  {ids={}, func=rightCol}
}

-- Push speed values for floor conveyors
local groundedPush = {
}

-- Push speed values for wall conveyors
local pushTable = {
}

function wallcon.addGroundedConveyor(id, speed)
	groundedPush[id] = speed
end

function wallcon.addWallConveyor(id, speed, wallDirection)
	pushTable[id] = speed
	facingTable[wallDirection].ids[id] = true
end

-- Default configuration. Change if necessary.
wallcon.addGroundedConveyor(755, -1)
wallcon.addGroundedConveyor(756, 1)

wallcon.addWallConveyor(757, 0.5, 1)
wallcon.addWallConveyor(758, -1, 1)

wallcon.addWallConveyor(759, -1, -1)
wallcon.addWallConveyor(760, 0.5, -1)

function wallcon.onInitAPI()
    registerEvent(wallcon, "onInputUpdate")
    registerEvent(wallcon, "onTick")
    registerEvent(wallcon, "onTickEnd")
end

function wallcon.onInputUpdate()
	if wasColliding and not Misc.isPausedByLua() then
		player.runKeyPressing = false
		player.downKeyPressing = false
	end
end

function wallcon.onTick()
    if wasColliding then
        player.runKeyPressing = true
    end
    if directionLock then
        player.direction = directionLock
        player.leftKeyPressing = false
        player.rightKeyPressing = false
    end
end

function wallcon.onTickEnd()
	if botCol() then
		local collides = false
		for k,v in ipairs(BGO.getIntersecting(player.x, player.y, player.x + player.width, player.y + player.height)) do
			if (groundedPush[v.id]) and not v.isHidden then
				collides = v.id
				break
			end
		end
		if collides then
			player.speedX = player.speedX + groundedPush[collides]
		end
	end
	
	if wallCD == 0 and facingTable[player.direction].func() then
		local collides = false
		for k,v in ipairs(BGO.getIntersecting(player.x, player.y, player.x + player.width, player.y + player.height)) do
			if facingTable[player.direction].ids[v.id] and not v.isHidden then
				collides = v.id
				break
			end
		end
		if collides then
			directionLock = player.direction
			if not wasColliding then
				player:mem(0x50, FIELD_BOOL, false)
			end
			player.speedX = 0.3 * player.direction
			player.speedY = math.clamp(-14, player.speedY + pushTable[collides], 8)
			player:mem(0x114, FIELD_WORD, wallcon.hangingFrame)
			if player.keys.jump == KEYS_PRESSED then
				player.speedX = 7 * -player.direction
				player.speedY = -7
				wallCD = 15
				SFX.play(2)
			end
		end
		wasColliding = collides ~= false
	else
		if wallCD > 0 then
			wallCD = wallCD - 1
		end
		directionLock = nil
		wasColliding = false
	end
end

return wallcon