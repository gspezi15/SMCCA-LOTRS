local npc = {}

local id = NPC_ID

local npcManager = require 'npcManager'
local bossHp = require 'bossNPC/bossHp'

npcManager.setNpcSettings{
	nogravity = true,
	noiceball = true,
	noyoshi = true,
	
	id = id,
	
	frames = 1,
}

npcManager.registerHarmTypes(id,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

local function initAnimation(v, data, settings)
	local code = settings.customAnimation
	
	if code ~= nil then
		code = [[
			return function()
				return {]] .. code .. [[}
			end
		]]
		
		local env = require('bossNPC/animation').init(v, data, settings)
	
		local chunk = assert(load(code, code, "t", env))
		data.customAnimation = chunk()
	end
end

local function initPhases(v, data, settings)
	local env = require('bossNPC/phasing').init(v, data, settings)
	
	local name = settings.phasesFile or "bossExample.lua"
	local f = assert(loadfile(Misc.resolveFile(name), "t", env))
	
	data.phases = f()
end

local function initHarmEvent(v, data, settings)
	local code = [[return function(event, npc, reason, culprit)
				]] .. (settings.harmEvent or "") .. [[
					end]]
				
	data.harmEvent = loadstring(code)()
end

local function initCode(v, data, settings)
	local code = [[return function(event, npc, reason, culprit)
				]] .. (settings.initCode or "") .. [[
					end]]
				
	local chunk = loadstring(code)()
	chunk(v, data, settings)
end

local function initRender(v, data, settings)
	local code = settings.customRender
	
	if code ~= nil then
		code = [[
			return function()
				return {]] .. code .. [[}
			end
		]]
		
		local env = require('bossNPC/animation').init(v, data, settings)
	
		local chunk = assert(load(code, code, "t", env))
		data.customAnimation = chunk()
	end
end

local function initData(v, data, settings)
	if settings.group then
		for k,v in pairs(settings.group) do
			-- Misc.dialog(k,v)
			settings[k] = v
		end
		
		settings.group = nil
	end

	-- local phasesCode = [[
		-- return {]] .. settings.phasesCode .. [[}]]
	
	local cfg = NPC.config[id]
	
	data.friendly = v.friendly
	
	-- other
	v.noblockcollision = settings.noblockcollision or false
	
	-- size
	local width = settings.width
	if width == nil or width == 0 then
		width = 32
	end
	
	local height = settings.height
	if height == nil or height == 0 then
		height = 32
	end
	
	v.width = width
	v.height = height
	
	if settings.effect and settings.effect ~= 0 then
		data.effect = settings.effect
	end
	
	-- hp
	data.maxHp = settings.maxHP or 5
	data.hp = data.maxHp
	data.drawHp = settings.drawHp
	
	if settings.customHp and settings.customHp ~= "" and (settings.drawHp == nil or settings.drawHp == 0) then
		local file = loadfile(settings.customHp)
		
		data.drawHp = file().draw
	end
	
	-- gravity
	data.nogravity = settings.nogravity or false
	
	-- animation
	data.frame = 0
	data.frameTimer = 0
	data.frameSpeed = settings.frameSpeed or 8
	data.frameStyle = (settings.frameStyle or 2) - 1
	
	data.frames = settings.frames or cfg.frames
	
	local frames = data.frames
	
	if data.frameStyle == 1 then
		frames = frames + frames
	elseif data.frameStyle == 2 then
		frames = (frames + frames) * 2
	end
	
	initAnimation(v, data, settings)
	initRender(v, data, settings)
	
	-- sprite
	local texture = settings.textureFilename or id
	
	if tonumber(texture) ~= nil then
		texture = tonumber(texture)
	end
	
	if type(texture) == 'number' then
		local nId = texture
		if nId == 0 then
			nId = id 
		end
		
		texture = Graphics.sprites.npc[nId].img
	else
		texture = Graphics.loadImageResolved(texture)
	end
	
	data.sprite = Sprite{
		texture = texture,
		
		x = v.x, 
		y = v.y, 
		
		frames = frames, 
		
		pivot = vector(0.5, 1),
	}
	
	data.spriteHidden = false
	
	if settings.bossIcon and settings.bossIcon ~= "" then
		data.icon = Graphics.loadImageResolved(settings.bossIcon)
	else
		data.icon = texture
	end
	
	-- harm types
	initHarmEvent(v, data, settings)
	
	settings.harmtype1 = settings.harmtype1 or 1
	settings.harmtype2 = settings.harmtype2 or 1
	settings.harmtype3 = settings.harmtype3 or 1

	settings.harmtype5 = settings.harmtype5 or 1

	settings.harmtype7 = settings.harmtype7 or 1
	settings.harmtype8 = settings.harmtype8 or 1
	settings.harmtype10 = settings.harmtype10 or 1

	-- for phases
	data.stop = 0
	data.phase = 0
	
	data.attack = 0
	data.attackTimer = 0
	data.timer = 0
	
	initPhases(v, data, settings)
	initCode(v, data, settings)
end

local function phasing(v, data)
	if data.stop > 0 then
		data.stop = data.stop - 1
		return
	end
	
	local phases = data.phases
	local phaseCount = (data.phase + 1)
	local phaseObj = phases[phaseCount]
	
	local attackCount = (data.attack + 1)
	local attackObj = phaseObj[attackCount]
	
	data.timer = data.timer + 1
	
	if phaseObj.condition then
		local nextPhase = phaseObj.condition()
		
		if nextPhase then
			data.attack = 0
			data.attackTimer = 0
			data.timer = 0
			
			data.phase = (data.phase + 1) % #phases
			return
		end
	end
	
	local global = phaseObj.global
	
	if global then
		global()
	end
	
	local continue = attackObj()

	if continue then
		data.attackTimer = 0
		data.timer = 0
		
		if type(continue) == 'number' then
			data.attack = (continue - 1)
		else
			data.attack = (data.attack + 1) % #phaseObj
		end
	end
end

function immunity(v, data)
	if v:mem(0x156, FIELD_WORD) > 0 then
		v.friendly = true
	else
		v.friendly = data.friendly
	end
end

local function framestuff(v, data)
	local frames  = data.frames
	local framespeed = data.frameSpeed
	local framestyle = data.frameStyle
	
	if(frames > 0) then
		data.frameTimer = data.frameTimer + 1
		if(framestyle == 2 and (v.projectile ~= 0 or v.holdingPlayer > 0)) then
			data.frameTimer = data.frameTimer + 1
		end
		if(data.frameTimer >= framespeed) then
			if(framestyle == 0) then
				data.frame = data.frame + 1 * v.direction
			else
				data.frame = data.frame + 1
			end
			data.frameTimer = 0
		end
		if(framestyle == 0) then
			if(data.frame >= frames) then
				data.frame = 0
			end
			if(data.frame < 0) then
				data.frame = frames - 1
			end
		elseif(framestyle == 1) then
			if(v.direction == -1) then
				if(data.frame >= frames) then
					data.frame = 0
				end
				if(data.frame < 0) then
					data.frame = frames
				end
			else
				if(data.frame >= frames * 2) then
					data.frame = frames
				end
				if(data.frame < frames) then
					data.frame = frames
				end
			end
		elseif(framestyle == 2) then
			if(v:mem(0x12C, FIELD_WORD) == 0 and v:mem(0x136, FIELD_BOOL) == 0) then
				if(v.direction == -1) then
					if(data.frame >= frames) then
						data.frame = 0
					end
					if(data.frame < 0) then
						data.frame = frames - 1
					end
				else
					if(data.frame >= frames * 2) then
						data.frame = frames
					end
					if(data.frame < frames) then
						data.frame = frames * 2 - 1
					end
				end
			else
				if(v.direction == -1) then
					if(data.frame >= frames * 3) then
						data.frame = frames * 2
					end
					if(data.frame < frames * 2) then
						data.frame = frames * 3 - 1
					end
				else
					if(data.frame >= frames * 4) then
						data.frame = frames * 3
					end
					if(data.frame < frames * 3) then
						data.frame = frames * 4 - 1
					end
				end
			end
		end
	end
end

local function animation(v, data)
	local sprite = data.sprite
	local pivot = sprite.pivot
	
	sprite.x = v.x + (v.width * pivot[1])
	sprite.y = v.y + (v.height * pivot[2])
	
	if data.sprites then
		for k,spr in ipairs(data.sprites) do
			local sprite = spr.obj
			
			local ox = spr.x or 0
			local oy = spr.y or 0
			
			sprite.x = v.x + (v.width * pivot[1]) + ox
			sprite.y = v.y + (v.height * pivot[2]) + oy
		end
	end
	
	if data.frameStyle ~= -1 then
		framestuff(v, data)
	end
	
	if data.customAnimation then
		data.customAnimation()
	end
end

function npc.onTickEndNPC(v)
	if v.despawnTimer <= 0 or v.isHidden or Defines.levelFreeze then
		return
	end
	
	local data = v.data
	local settings = data._settings
	
	if not data.init then
		initData(v, data, settings)
		data.init = true
	end
	
	if not data.nogravity then
		v.speedY = v.speedY + Defines.npc_grav
	end
	
	phasing(v, data)
	immunity(v, data)
	animation(v, data)
	
	v.despawnTimer = 180
end

local immunityStyles = {
	[1] = function(v) -- Flashing
		return Color.white .. math.random()
	end,
	
	[2] = function(v) -- Flashing 2.0
		local alpha = math.random() * 0.75

		return Color.white .. alpha
	end,
	
	[3] = function(v) -- Smooth
		local time = lunatime.tick() / 6
		local alpha = math.sin(time)
		
		if alpha < 0.5 then
			alpha = 0.5
		end
		
		return Color.white .. alpha
	end,
	
	[4] = function(v) -- Translucent
		return Color.white .. 0.5
	end,
}

function npc.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then
		return
	end
	
	local data = v.data
	local settings = data._settings
	
	if not data.init then return end
	
	local col = data.color or Color.white
	
	if v:mem(0x156, FIELD_WORD) > 0 then
		local style = immunityStyles[settings.immunityStyle or 2]
		
		if style then
			col = style(v)
		end
	end
	
	if data.customAnimation then
		data.customAnimation()
	end
	
	if not data.spriteHidden then
		data.sprite:draw{
			frame = data.frame + 1,
			
			color = col,
			
			priority = -45.1,
			sceneCoords = true,
		}
	end
	
	if data.sprites then
		for k,sprite in ipairs(data.sprites) do
			sprite.obj:draw{
				frame = (sprite.frame or data.frame) + 1,
				
				color = col,
				
				priority = -45.1,
				sceneCoords = true,
			}
		end
	end
	
	local style = data.drawHp or 0
	
	bossHp.draw(style, {
		hp = data.hp,
		maxHp = data.maxHp,
		
		name = settings.bossName or "Boss",
		icon = data.icon, 
	})
end

function npc.onNPCHarm(e, v, r, c)
	if v.id ~= id then return end
	
	if v:mem(0x156, FIELD_WORD) > 0 then
		e.cancelled = true
		return
	end
	
	local data = v.data	
	local settings = data._settings
	
	if r == 6 and settings.nolava then
		e.cancelled = true
		return
	end

	if c and c.id == 13 then
		e.cancelled = true
		return
	end
	
	local dmg = settings['harmtype' .. r] or 1
	
	if dmg <= 0 then
		e.cancelled = true
		return
	end
	
	if data.hp > 1 then
		v:mem(0x156, FIELD_WORD, settings.immunityMax or 75)
		data.hp = (data.hp - dmg)
		
		e.cancelled = true
		return
	end
	
	if data.effect and r ~= HARM_TYPE_LAVA then
		Effect.spawn(data.effect, v.x, v.y)
	end
	
	Routine.run(data.harmEvent, e, v, r, c)
end

function npc.onInitAPI()
	registerEvent(npc, 'onNPCHarm')
	
	npcManager.registerEvent(id, npc, 'onDrawNPC')
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
end

return npc