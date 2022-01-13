--Boss creation library by Enjl
--Ver. 1.0.0
--[[	
	adversary.createBoss(string sprite, props) --initiates a boss, sprite required
		props:
			x | 0
			y | 0
			z | -45
			useScreenCoords | false
			opacity | 1
			state | 0
			speedX | 0
			speedY | 0
			frameX | 0 --sheet frame offset
			frameY | 0
			width | sprite.width --hitbox
			height | sprite.height
			gfxwidth | width
			gfxheight | height
			name | "Boss"
			gfxOffsetX | 0 --offset of sprite relative to x and y
			gfxOffsetY | 0
			hp | 3
			active | false
			
			))) end of passable variables. anything else added to the props table is copied over for the boss.
	collider --box collider
	maxHP
	displayedHP
	HPInitialised
	hpVisible
	
	boss.__type = "Boss"
	
	boss:draw() --draws the boss
	boss:initHP() --initialised HP bar
	boss:drawHP(number) --automatically called if hpVisible is true, includes number in boss list
	boss:toggleHP() --toggles HP bar visibility
	boss:onTick() --like onTick but for the boss
	boss:onDraw() --like onDraw but for the boss
	boss:onHarm(source, damage, culprit) --invoked whenever damage occurs, allows customisation of dealt damage
	boss:damage(amount) --deal damage to the boss
	boss:heal(amount) = --heal the boss
	boss:isDefeated() = --check if the boss is dead
	boss:registerHarmSource(source, damage) = --map harm source to damage amount
	boss:registerCollider(collider, harmmultiplier) = --register nonstandard colliders to harm source management
	boss:registerStateHarm(table of state harm map) = --register harm multiplier for specific states
	boss:remove() -- permanently kills the boss
]]

local adversary = {}

--update font

local textplus = require("textplus")

adversary.hpFont = textplus.loadFont("textplus/font/6.ini")

adversary.HARM_JUMP = -1
adversary.HARM_SLASH = -2
adversary.HARM_DOWNSLASH = -3
adversary.HARM_TAIL = -4
adversary.HARM_TONGUE = -5
adversary.HARM_FIREBALL = 13
adversary.HARM_HAMMER = 171
adversary.HARM_ICEBALL = 265
adversary.HARM_LASER = 266

local function loadImage(str)
	return Graphics.loadImage(Misc.resolveFile(str))
end

adversary.hpBorder = loadImage("adversary/hpBorder.png")
adversary.hpBackdrop = loadImage("adversary/hpBackdrop.png")
adversary.hpSlice = loadImage("adversary/hpSlice.png")
adversary.hpSlicer = loadImage("adversary/hpSlicer.png")
adversary.hpSliceRed = loadImage("adversary/hpSliceRed.png")

adversary.bossHPCoords = vector.v2(782, 560) --upper right bound to make positioning of other objects easier
adversary.bossHPBarDimensions = vector.v2(180, 12)
adversary.HPOffset = vector.v2(-34, 4)
adversary.backdropOffset = vector.v2(-214, 4)

--boss init
local bossTable = {}

local function remove(boss)
	for k,v in ipairs(bossTable) do
		if v == boss then
			table.remove(bossTable, k)
		end
	end
end

local function registerStateHarmInternal(boss, tbl)
	boss._stateharm = table.join(tbl, boss._stateharm)
end

local function registerHarmInternal(boss, source, damage)
	local oldSource = source
	if type(source) == "number" then
		if source < 0 then
			if source == adversary.HARM_JUMP then
				source = function(a)
					for k,v in ipairs(Player.get()) do
						if Colliders.bounce(v, a) then
							return true, v
						end
					end
					return false, nil
				end
			elseif source == adversary.HARM_SLASH then
				source = function(a)
					for k,v in ipairs(Player.get()) do
						if Colliders.slash(v, a) then
							return true, v
						end
					end
					return false, nil
				end
			elseif source == adversary.HARM_DOWNSLASH then
				source = function(a)
					for k,v in ipairs(Player.get()) do
						if Colliders.downSlash(v, a) then
							return true, v
						end
					end
					return false, nil
				end
			elseif source == adversary.HARM_TAIL then
				source = function(a)
					for k,v in ipairs(Player.get()) do
						if Colliders.tail(v, a) then
							return true, v
						end
					end
					return false, nil
				end
			elseif source == adversary.HARM_TONGUE then
				source = function(a)
					for k,v in ipairs(Player.get()) do
						if Colliders.tongue(v, a) then
							return true, v
						end
					end
					return false, nil
				end
			end
		else
			local src = source
			source = function(a)
				local b,_,t = Colliders.collideNPC(a, src)
				if b then
					t = t[1]
				end
				return b,t
			end
		end
	end
	
	if type(source) == "string" then
		local t = {
			damage = damage,
			puresource = oldSource
		}
		boss._harmTypes[source] = t
	else
		local t = {
			condition = source,
			damage = damage,
			puresource = oldSource
		}
		table.insert(boss._harmTypes, t)
	end
end

local function registerColliderInternal(boss, collider, harmMultiplier)
	local colWrapper = {collider = collider, mult = harmMultiplier}
	table.insert(boss._colliders, colWrapper)
end

local function drawBoss(boss)
	if boss.useScreenCoords then
		Graphics.drawImageWP(boss.sprite, boss.x + boss.gfxOffsetX, boss.y + boss.gfxOffsetY, boss.frameX * boss.gfxwidth, boss.frameY * boss.gfxheight, boss.gfxwidth, boss.gfxheight, boss.opacity, boss.z)
	else
		Graphics.drawImageToSceneWP(boss.sprite, boss.x + boss.gfxOffsetX, boss.y + boss.gfxOffsetY, boss.frameX * boss.gfxwidth, boss.frameY * boss.gfxheight, boss.gfxwidth, boss.gfxheight, boss.opacity, boss.z)
	end
end

local function drawBossHP(boss, number)
	local offsetX = number
	local y = adversary.bossHPCoords.y
	local w = adversary.bossHPBarDimensions.x + 60
	local x = adversary.bossHPCoords.x - (w) * (offsetX - 1)
	while x <= w do
		x = x + math.ceil((adversary.bossHPCoords.x - w)/ w) * w
		y = y - (adversary.bossHPBarDimensions.y + 36)
	end

	local shakeFactor = 0

	textplus.print{
		x = x,
		y = y,
		xscale = 2,
		yscale = 2,
		text = boss.name,
		font= adversary.hpFont,
		pivot = vector(1, 1),
		priority = 5
	}

	if boss.hpShake > 0 then
		shakeFactor = math.min(5, boss.hpShake) * (2*(boss.hpShake%2)-1)
	end
	x = x + shakeFactor
	
	local hpLength = x + adversary.HPOffset.x - (boss.displayedHP/boss.maxHP) * adversary.bossHPBarDimensions.x
	local hpLengthOld = x + adversary.HPOffset.x - (boss.displayedHPLag/boss.maxHP) * adversary.bossHPBarDimensions.x

	local sliceTexCoords = {1,0,0,0,0,1,1,1}
	sliceTexCoords[3] = 1-(boss.displayedHP/boss.maxHP)
	sliceTexCoords[5] = sliceTexCoords[3]
	
	Graphics.drawImageWP(adversary.hpBorder, x - adversary.hpBorder.width, y, 5)
	Graphics.drawImageWP(adversary.hpBackdrop, x + adversary.backdropOffset.x, y + adversary.backdropOffset.y, 4.9)
	Graphics.glDraw{texture=adversary.hpSlice, primitive = Graphics.GL_TRIANGLE_FAN, priority = 4.95, 
					vertexCoords = {x + adversary.HPOffset.x,
										y + adversary.HPOffset.y,
										
									hpLength,
									
										y + adversary.HPOffset.y, 
										
									hpLength,
									
										y + adversary.HPOffset.y + adversary.bossHPBarDimensions.y,
										
									x + adversary.HPOffset.x,
									
										y + adversary.HPOffset.y + adversary.bossHPBarDimensions.y
									}, textureCoords=sliceTexCoords}
	Graphics.glDraw{texture=adversary.hpSliceRed, primitive = Graphics.GL_TRIANGLE_FAN, priority = 4.94, 
					vertexCoords = {x + adversary.HPOffset.x,
										y + adversary.HPOffset.y,
										
									hpLengthOld,
									
										y + adversary.HPOffset.y, 
										
									hpLengthOld,
									
										y + adversary.HPOffset.y + adversary.bossHPBarDimensions.y,
										
									x + adversary.HPOffset.x,
									
										y + adversary.HPOffset.y + adversary.bossHPBarDimensions.y
									}, textureCoords={0,0,1,0,1,1,0,1}}

	for k,v in ipairs(boss.hpSlicerTable) do
		if boss.hp > v then
			Graphics.drawBox{
				texture = adversary.hpSlicer,
				x = x + adversary.HPOffset.x - (v/boss.maxHP) * adversary.bossHPBarDimensions.x - 0.5 * adversary.hpSlicer.width,
				y = y + adversary.HPOffset.y,
				priority = 4.95,
			}
		end
	end
end

local function initHP(boss)
	boss.hpVisible = true
	local step = boss.maxHP/120
	while boss.displayedHP < boss.hp do
		boss.displayedHP = boss.displayedHP + step
		Routine.waitFrames(1)
	end
	boss.displayedHP = boss.hp
	boss.displayedHPLag = boss.displayedHP
	boss.HPInitialised = true
end

local function toggleHP(boss)
	boss.hpVisible = not boss.hpVisible
end

local function damageBoss(boss, damage, ignoreIFrames)
	if type(damage) == "string" then
		local h = boss._harmTypes[damage]
		local dmg = h.damage * (boss._stateharm[boss.state] or 1)
		if (not ignoreIFrames) and boss.iFrames > 0 then
			dmg = 0
		end
		dmg = boss:onHarm(h.puresource, dmg) or dmg
		if dmg > 0 then
			boss:damage(dmg)
		end
	else
		boss.hp = math.max(boss.hp - damage, 0)
		if boss.HPInitialised then
			boss.displayedHP = boss.hp
			boss.hpLagTimer = 65
			if damage > 0 then
				boss.hpShake = 2 + math.ceil(damage)
			end
		end
	end
end

local function addHPSlicer(boss, hpValue)
	table.insert(boss.hpSlicerTable, hpValue)
end

local function healBoss(boss, heal)
	boss.hp = math.min(boss.hp + heal, boss.maxHP)
	if boss.HPInitialised then
		boss.displayedHP = boss.hp
		boss.hpLagTimer = 65
	end
end

local function init(this, default)
	if not this then
		return default
	end
	return this
end

function adversary.createBoss(sprite, props)
	if props == nil then props = {} end
	local boss = props
	
	if sprite then
		if type(sprite) ~= "LuaImageResource" then
			boss.sprite = loadImage(sprite)
		else
			boss.sprite = sprite
		end
	end
	
	boss.x = init(boss.x, 0)
	boss.y = init(boss.y, 0)
	boss.z = init(boss.z, -45)
	
	boss.sceneCoords = init(boss.sceneCoords, true)
	
	boss.opacity = init(boss.opacity, 1)
	
	boss.state = init(boss.state, 0)
	
	boss.speedX = init(boss.speedX, 0)
	boss.speedY = init(boss.speedY, 0)
	
	boss.frameX = init(boss.frameX, 0)
	boss.frameY = init(boss.frameY, 0)

	boss.iFrames = 0
	
	boss.width = boss.width or boss.sprite.width
	boss.height = boss.height or boss.sprite.height
	
	boss.gfxwidth = boss.gfxwidth or boss.width
	boss.gfxheight = boss.gfxheight or boss.height
	
	boss.collider = Colliders.Box(boss.x, boss.y, boss.width, boss.height)
	boss.hpShake = 0
	
	boss.name = init(boss.name, "Boss")
	
	boss.gfxOffsetX = init(boss.gfxOffsetX, 0)
	boss.gfxOffsetY = init(boss.gfxOffsetY, 0)
	
	boss.hp = init(boss.hp, 3)
	boss.maxHP = init(boss.maxHP, boss.hp)
	boss.displayedHP = 0
	boss.displayedHPLag = 0
	boss.hpLagTimer = 0
	boss.HPInitialised = false
	boss.hpVisible = false
	
	boss.active = init(boss.active, false)
	
	boss.__type = "Boss"
	boss.isValid = true
	boss._harmTypes = {}
	boss._stateharm = {}
	boss._colliders = {}
	
	boss.draw = drawBoss
	boss.initHP = function(boss) Routine.run(function() initHP(boss) end) end
	boss.drawHP = drawBossHP
	boss.toggleHP = toggleHP
	boss.damage = damageBoss
	boss.remove = remove
	boss.heal = healBoss
	boss.isDefeated = function (boss) return boss.hp == 0 end
	boss.registerHarmSource = registerHarmInternal
	boss.registerCollider = registerColliderInternal
	boss.registerStateHarm = registerStateHarmInternal
	boss.hpSlicerTable = {}
	boss.addHPSlicer = addHPSlicer
	
	registerCustomEvent(boss, "onTick");
	registerCustomEvent(boss, "onDraw");
	
	table.insert(bossTable, boss)
	return boss
end

function adversary.onInitAPI()
	registerEvent(adversary, "onTick")
	registerEvent(adversary, "onDraw")
end

function adversary.onTick()
	for k,v in ipairs(bossTable) do
		if v.active then
			for k,c in ipairs(v._colliders) do
				for k,h in ipairs(v._harmTypes) do
					local b, culprit = h.condition(c.collider)
					if b then
						local dmg = h.damage * (v._stateharm[v.state] or 1) * c.mult
						if v.iFrames > 0 then
							dmg = 0
						end
						dmg = v:onHarm(h.puresource, dmg, culprit) or dmg
						if dmg > 0 then
							v:damage(dmg)
						end
					end
				end
			end
			v:onTick(k)
		end
		if v.hpVisible and v.HPInitialised then
			v.hpLagTimer = v.hpLagTimer - 1
			v.hpShake = math.max(v.hpShake - 1, 0)
			if v.hpLagTimer < 0 then
				if v.displayedHP < v.displayedHPLag then
					v.displayedHPLag = v.displayedHPLag - 0.04
				else
					v.displayedHPLag = v.displayedHP
				end
			end
		end
	end
end

function adversary.onDraw()
	local activeNumber = 0
	for k,v in ipairs(bossTable) do
		if v.active then
			v:onDraw(k,v)
		end
		if v.hpVisible then
			activeNumber = activeNumber + 1
			v:drawHP(activeNumber)
		end
	end
end

return adversary