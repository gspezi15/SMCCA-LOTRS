local phases = {}

local function firstAttack()
	move(2) -- move command not only sets speed, but it also accounts for npc's direction
	-- jump(6) -- jump command activates only when npc is on ground
	return stopAttack(128) -- stop attack when timer gets 128
end

local function secondAttack()
	move(0)
	jump(6)
	
	return stopAttack(128) -- stop attack when timer gets 128
end

addAttack(phases, 1, firstAttack) -- adds attack to first phase
addAttack(phases, 1, secondAttack)  -- adds attack to first phase
setCondition(phases, 1, function() -- a condition for phase changing
	return (hp < 3) 
end)

addAttack(phases, 2, secondAttack)  -- adds attack to second phase
return phases