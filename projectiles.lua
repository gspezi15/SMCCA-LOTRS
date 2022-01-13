--projectile library by Enjl
--version 1.0.0
--[[projectiles.createList(defaults) --creates a new npc list. Call outside of functions. Returns npc list.
	defaults: --set default parameters for list ( | indicates backup variable)
		x | 0
		y | 0
		z | -45 --priority
		width | 8 --hitbox
		height | 8
		speedX | 0
		speedY | 0
		bindX | projectiles.BIND_CENTRE --sprite bind relative to x/y
		bindY | projectiles.BIND_CENTRE
		sprite --string
		gfxwidth | this.width --gfx dimensions
		gfxheight | this.height
		deathEffect (table) --stuff for death effects
			sprite | this.sprite --string
			frames | 1
			framespeed | 8
			priority | this.z
			timer | 250
			sound
		
		))) end of passable variables
		drawing & frames for projectiles is to be handled by the user

	projectileTable.__type = "projectile list"
	
	projectileTable:onTick(k,v) --like onTick but for the projectile routine, passes k and v (defined in lunadll.lua)
	projectileTable:onDraw(k,v) --like onDraw but for the projectile routine, passes k and v (defined in lunadll.lua)
	projectileTable:spawn(props) --spawns a projectile from the table, returns new projectile
		props: --override table defaults
			x | projectileTable.x
			y | projectileTable.y
			z | projectileTable.z
			width | projectileTable.width
			height | projectileTable.height
			gfxwidth | projectileTable.gfxwidth
			fxheight | projectileTable.gfxheight
			speedX | projectileTable.speedX
			speedY | projectileTable.speedY
			bindX | projectileTable.bindX
			bindY | projectileTable.bindY
			sprite | projectileTable.sprite --string
			
			deathEffect (table) --stuff for death effects
					sprite | this.sprite --string
					frames | projectileTable.deathEffect.frames
					framespeed | projectileTable.deathEffect.framespeed
					priority | this.z
					timer | projectileTable.deathEffect.timer
					sound
			))) end of passable variables
			
		collider --box collider
		sprOffsetX --calculates offset from sprite to object
		sprOffsetY
		colOffsetX --same but for the collider
		colOffsetY
		
		projectile.__type = "toolkit projectile"
		
		projectile:kill(int effect (see EFFECT_ constants), int number (number of effects to spawn), bool playSound)
		projectile:collides(v2/obj target, int buffer) --checks for collision (uses collider)]]
		
local projectiles = {}

local function loadImg(str)
	if type(str) == "LuaImageResource" then
		return str
	end
	return Graphics.loadImage(Misc.resolveFile(str))
end

projectiles.EFFECT_DESPAWN = 0
projectiles.EFFECT_FALL = 1
projectiles.EFFECT_BONK = 2
projectiles.EFFECT_STAY = 3

projectiles.BIND_CENTRE = 0
projectiles.BIND_MID = 0
projectiles.BIND_CENTER = 0
projectiles.BIND_BOTTOM = 1
projectiles.BIND_RIGHT = 1

--custom projectiles

local function bind(v, bindType)
	return v * bindType
end

projectiles.lists = {}

local projectileEffects = {}

local function checkNil(field, default)
	if not field then field = default end
	return field
end
--[[
local function fillTable(source, newStuff)
	local new = table.deepclone(source)
	if newStuff then
		for k,v in pairs(newStuff) do
			new[k] = v
		end
	end
	return new
end
]]

local function getIntersecting(tbl, x, y, w, h, firstOnly)
	
	local result = {}
	
	local xMult = {0,1}
	local yMult = {0,1}
	
	if tbl.bindX == projectiles.BIND_CENTRE then
		xMult = {-0.5, 0.5}
	elseif tbl.bindX == projectiles.BIND_RIGHT then
		xMult = {-1, 0}
	end
	
	if tbl.bindY == projectiles.BIND_CENTRE then
		yMult = {-0.5, 0.5}
	elseif tbl.bindY == projectiles.BIND_BOTTOM then
		yMult = {-1, 0}
	end
	
	for k,v in ipairs(tbl.entries) do
		if  v.x + xMult[1] * v.width  < x + w
		and v.y + yMult[1] * v.height < y + h
		and v.x + xMult[2] * v.width  > x
		and v.y + yMult[2] * v.height > y then
			table.insert(result, v)
			
			if (firstOnly) then
				break
			end
		end
	end
	
	return result
end

local function isColliding(a, b, bufferSize)
    if b == nil then b = camera end

    local x1 = a.x
    local x2 = b.x
    local y1 = a.y
    local y2 = b.y
    local w1 = a.width or 0
    local w2 = b.width or 0
    local h1 = a.height or 0
    local h2 = b.height or 0
    if bufferSize == nil then bufferSize = 0 end
    if x1 < x2 - w1 - bufferSize then
        return false
    end
    if x1 > x2 + w2 + bufferSize then
        return false
    end
    if y1 < y2 - h1 - bufferSize then
        return false
    end
    if y1 > y2 + h2 + bufferSize then
        return false
    end

    return true;
end

local function spawn(tbl, props)
	local entry = props
	entry.x = checkNil(entry.x, tbl.x)
	entry.y = checkNil(entry.y, tbl.y)
	entry.z = checkNil(entry.z, tbl.z)
	
	entry.width = checkNil(entry.width, tbl.width)
	entry.height = checkNil(entry.height, tbl.height)
	
	entry.speedX = checkNil(entry.speedX, tbl.speedX)
	entry.speedY = checkNil(entry.speedY, tbl.speedY)
	
	entry.bindX = checkNil(entry.bindX, tbl.bindX)
	entry.bindY = checkNil(entry.bindY, tbl.bindY)
	
	entry.gfxwidth = checkNil(entry.gfxwidth, tbl.gfxwidth)
	entry.gfxheight = checkNil(entry.gfxheight, tbl.gfxheight)
	
	if entry.sprite then
		entry.sprite = loadImg(entry.sprite)
	else
		entry.sprite = tbl.sprite
	end
	
	entry.deathEffect = checkNil(entry.deathEffect, tbl.deathEffect)
	entry.deathEffect.sprite = checkNil(entry.deathEffect.sprite, tbl.deathEffect.sprite)
	entry.deathEffect.frames = checkNil(entry.deathEffect.frames, tbl.deathEffect.frames)
	entry.deathEffect.framespeed = checkNil(entry.deathEffect.framespeed, tbl.deathEffect.framespeed)
	entry.deathEffect.z = checkNil(entry.deathEffect.z, tbl.deathEffect.z)
	entry.deathEffect.timer = checkNil(entry.deathEffect.timer, tbl.deathEffect.timer)
		
	entry.collider = Colliders.Box(entry.x, entry.y, entry.width, entry.height)

	entry.sprOffsetX = bind(entry.gfxwidth, entry.bindX)
	entry.sprOffsetY = bind(entry.gfxheight, entry.bindY)
	
	entry.colOffsetX = bind(entry.width, entry.bindX)
	entry.colOffsetY = bind(entry.height, entry.bindY)
	entry.collider.x = entry.collider.x + entry.colOffsetX
	entry.collider.y = entry.collider.x + entry.colOffsetY
	
	entry.__type = "toolkit projectile"
	
	entry.kill = function(v, fx, number, playSound)
		v.killEffect = fx or 0
		v.playSound = (playSound == true)
		v.spread = number or 1
		v.dead = true
	end
	
	entry.collides = function(v, target, buffer)
		local w = v
		w.x = v.collider.x + v.colOffsetX
		w.y = v.collider.y + v.colOffsetY
		return isColliding(w, target, buffer)
	end

	table.insert(tbl.entries, entry)
	
	entry.__ref = tbl.entries
	
	return entry
end

function projectiles.createList(defaults)
	tbl = defaults or {}
	
	tbl.x = checkNil(tbl.x, 0)
	tbl.y = checkNil(tbl.y, 0)
	tbl.z = checkNil(tbl.z, -45)
	
	tbl.width = checkNil(tbl.width, 8)
	tbl.height = checkNil(tbl.height, 8)
	
	tbl.speedX = checkNil(tbl.speedX, 0)
	tbl.speedY = checkNil(tbl.speedY, 0)
	
	tbl.bindX = checkNil(tbl.bindX, projectiles.BIND_CENTRE)
	tbl.bindY = checkNil(tbl.bindY, projectiles.BIND_CENTRE)
	
	if tbl.sprite then
		tbl.sprite = loadImg(defaults.sprite)
	end
	
	tbl.gfxwidth = checkNil(tbl.gfxwidth, tbl.width)
	tbl.gfxheight = checkNil(tbl.gfxheight, tbl.height)
	
	tbl.deathEffect = checkNil(tbl.deathEffect, {})
	tbl.deathEffect.sprite = checkNil(tbl.deathEffect.sprite, tbl.sprite)
	tbl.deathEffect.frames = checkNil(tbl.deathEffect.frames, 1)
	tbl.deathEffect.framespeed = checkNil(tbl.deathEffect.framespeed, 8)
	tbl.deathEffect.z = checkNil(tbl.deathEffect.z, tbl.z)
	tbl.deathEffect.timer = checkNil(tbl.deathEffect.timer, 250)
	
	tbl.entries = {}
	
	tbl.__type = "projectile list"
	
	tbl.spawn = spawn
	
	tbl.getIntersecting = getIntersecting
	
	registerCustomEvent(tbl, "onTick");
	registerCustomEvent(tbl, "onDraw");
	table.insert(projectiles.lists, tbl)
	return tbl
end

function projectiles.onInitAPI()
	registerEvent(projectiles, "onTick", "onTick", false)
	registerEvent(projectiles, "onDraw", "onDraw", false)
	registerEvent(projectiles, "onTickEnd", "onTickEnd", false)
end


function projectiles.onTick()
	if Defines.levelFreeze then return end
	for _, v in ipairs(projectiles.lists) do
		for k,w in ipairs(v.entries) do
			if not w.dead then
				v:onTick(k,w)
				w.x = w.x + w.speedX
				w.y = w.y + w.speedY
				w.collider.x, w.collider.y = w.x + w.colOffsetX + w.speedX, w.y +  w.colOffsetY + w.speedY
			end
		end
	end
	for i=#projectileEffects, 1, -1 do
		v = projectileEffects[i]
		v.x = v.x + v.speedX
		v.y = v.y + v.speedY
		v.speedX = v.speedX * v.frictionX
		v.speedY = v.speedY + v.gravity
		v.killTimer = v.killTimer - 1
		if v.killTimer == 0 then
			table.remove(projectileEffects,i)
		end
	end
end

function projectiles.onDraw()
	for _, v in ipairs(projectiles.lists) do
		for k,w in ipairs(v.entries) do
			v:onDraw(k,w)
		end
	end
	for i=#projectileEffects, 1, -1 do
		v = projectileEffects[i]
		Graphics.drawImageToSceneWP(v.sprite, v.x + v.sprOffsetX, v.y + v.sprOffsetY, 0, math.floor(v.killTimer/v.framespeed)%v.frames, v.width, v.height, 1, v.z)
	end
end

local function setupProjectile(w)
	local entry = {}
					entry.sprite = w.deathEffect.sprite
					entry.x = w.x
					entry.y = w.y
					entry.speedX = 0
					entry.speedY = 0
					entry.frictionX = 1
					entry.gravity = 0.26
					entry.frames = w.deathEffect.frames
					entry.width = entry.sprite.width
					entry.height = entry.sprite.height/entry.frames
					entry.sprOffsetX = w.sprOffsetX
					entry.sprOffsetY = w.sprOffsetY
					entry.framespeed = w.deathEffect.framespeed
					entry.offsetX = w.offsetX
					entry.offsetY = w.offsetY
					entry.killTimer = w.deathEffect.timer
					entry.type = w.killEffect
					entry.z = w.deathEffect.z
	return entry
end

function projectiles.onTickEnd()
	if Defines.levelFreeze then return end
	for _, v in ipairs(projectiles.lists) do
		for k,w in ipairs(v.entries) do
			if w.killEffect ~= nil then
				if w.killEffect > 0 then
					if w.spread == 1 then
						local entry = setupProjectile(w)
						if w.killEffect == projectiles.EFFECT_BONK then
							entry.speedX = -3 * (w.speedX/math.abs(w.speedX))
							entry.speedY = -4
							entry.frictionX = 0.985
							entry.gravity = 0.26
						elseif w.killEffect == projectiles.EFFECT_STAY then
							entry.gravity = 0
						end
						table.insert(projectileEffects, entry)
					else
						for i=1, w.spread do
							local entry = setupProjectile(w)
							if w.killEffect == projectiles.EFFECT_BONK then
								entry.speedX = RNG.random(-5, 5)
								entry.speedY = RNG.random(-3, -5)
								entry.frictionX = 0.985
								entry.gravity = 0.26
							elseif w.killEffect == projectiles.EFFECT_STAY then
								entry.gravity = 0
								entry.speedX = RNG.random(-3, 3)
								entry.speedY = RNG.random(-3, 3)
							end
							table.insert(projectileEffects, entry)
						end
					end
				end
				if w.playSound then
					SFX.play(projectiles.resolveFile(w.deathEffect.sound))
				end
				table.remove(v.entries, k)
				k = k - 1
			end
		end
	end
end

return projectiles