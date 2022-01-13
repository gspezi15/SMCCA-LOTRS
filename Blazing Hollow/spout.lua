--Benial's Spouts, flexible rising platforms
--Version 1.1

--Free £5.00 Tesco voucher for the first person to make this thing fall apart

local spout =  {}

local npcManager = require("npcManager")
local redirector = require("redirector")
local colliders = require("colliders")
local npcutils = require("npcs/npcutils")

local npcID = NPC_ID

--CUSTOM CONFIG VALUES
--bool lava: If enabled, the shaft instakills the player and vulnerable NPCs
--bool hurt: If enabled, the shaft hurts the player
--bool forcerise: If enabled, the shaft makes the player and solid NPCs rise to the top
--float heavylift: When "heavy" objects are rising in the shaft, the speed applied is divided by this value. Set to 0 to make them unliftable, or to 1 for regular speed.
--float resistance: When objects are rising in the shaft, their speedX is divided by this value. ≤ 0 means no resistance.
--bool fall: If enabled, the top sinks down rather than the bottom rising up
--float fallaccel: The acceleration that the spout falls at, if fall is enabled
--int effectID: ID of the effect to display continuously before rising
--float effectoffset: Allows manual adjustment for the spawn height of effects
--int headoffset: Offset of the head graphic (first section, uses regular gfxheight)
--int shaftheight: Height of the shaft graphic (second section)
--int tailoffset: Offset of the tail graphic (third section)
--int tailheight: Height of the tail graphic (third section)

local spoutMap = {}

local shared_settings = {
	noblockcollision = true,
	npcblock = false,
	nogravity = true,
	nogravity = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = true,
	harmlessthrown = true,
	grabside=false,
	grabtop=false,
	
	headoffset=0,
	shaftheight=32,
	tailheight=32,
	tailoffset=0,
	lava=false,
	hurt=false,
	forcerise=false,
	resistance=1.2,
	fall=false,
	effectID=0,
	effectoffset=0,
	fallaccel=0.1,
	heavylift=2
}

local riseRegister = {} --A table that holds manual NPC registrations. 1 = whitelist, -1 = blacklist

function spout.register(settings)
	local config = NPC.config[settings.id]
    spoutMap[settings.id] = true
    npcManager.registerEvent(settings.id, spout, "onTickNPC")
    npcManager.registerEvent(settings.id, spout, "onDrawNPC")
	npcManager.setNpcSettings(table.join(settings, shared_settings))
	columntex=Graphics.loadImage("npc-"..tostring(settings.id)..".png")
end

function spout.society() --Darko asked me to add this
	NPC.spawn(208,player.x+256,player.y-128,player.section)
	NPC.spawn(209,player.x+256+8,player.y-128+32,player.section)
	player.sectionObj.musicID = 45
end

--Allows an NPC to be lifted, where "ids" is a table of IDs
function spout.whitelistNPC(ids)
	for _,v in ipairs(ids) do
		table.insert(riseRegister,v,1)
	end
end

--Prevents an NPC from being lifted, where "ids" is a table of IDs
function spout.blacklistNPC(ids)
	for _,v in ipairs(ids) do
		table.insert(riseRegister,v,-1)
	end
end

--Checks for a terminus overlapping the spout NPC
local function getTerminus(x1,y1,x2,y2,v)
	for _,vx in ipairs(BGO.getIntersecting(x1,y1,x2,y2)) do
		if not vx.isHidden and vx.id == redirector.TERMINUS then
			if state == 1 then v.y = vx.y end
			return true
		end
	end
end

local function nextState(v)
	if lunatime.tick() >= v.data.switchtime then return true end
end

local function applyLayerMovement(npc)
	local layer = npc.layerObj
	if layer and not layer:isPaused() then
		npc.speedX = layer.speedX
		npc.y = npc.y + layer.speedY
		npc.data.startY = npc.data.startY + layer.speedY
	end
end

local function state_PreRise(npc)
	local data = npc.data
	local settings = npc.data._settings
	local config = NPC.config[npc.id]
	npc.y = npc.data.startY
	if lunatime.tick() >= npc.data.switchtime - math.max(30,settings.waitTime/6) and lunatime.tick()%4 == 0 and config.effectID > 0 and settings.doEffect then
		Animation.spawn(math.min(config.effectID,1000),math.random(npc.x,npc.x+npc.width),npc.y+config.effectoffset+settings.effectOffset)
	end
	if nextState(npc) then
		data.state = 1
		npc.friendly = false
	end
end

local function state_Rising(npc)
	local data = npc.data
	local settings = npc.data._settings
	local config = NPC.config[npc.id]
	npc.speedY = -3*(config.speed*settings.speed)
	data.spoutbottom = data.startY-(config.shaftheight-config.gfxheight)
	if getTerminus(npc.x,npc.y,npc.x+npc.width,npc.y+config.gfxheight,npc) or (data.startY-npc.y > settings.maxHeight and settings.maxHeight > 0) then
		data.state = 2
		data.switchtime = lunatime.tick() + settings.holdTime
	end
end

local function state_Peak(npc)
	local data = npc.data
	local settings = npc.data._settings
	local config = NPC.config[npc.id]
	npc.speedY = math.sin(lunatime.tick()/6)
	--Prevent objects on top of the spout from falling through it
	for _,vx in NPC.iterateIntersecting(npc.x,npc.y+1,npc.x+npc.width,npc.y+2) do
		if not NPC.config[vx.id].nogravity then
			vx.speedY = -3*(config.speed*settings.speed)
		end
	end
	if nextState(npc) then
		data.state = 3
		data.bottommovespeed = ((data.spoutbottom-npc.y-(config.shaftheight-config.gfxheight))/3)/(config.speed*settings.speed)
		data.switchtime = lunatime.tick() + data.bottommovespeed
	end
	data.spoutbottom = data.startY-(config.shaftheight-config.gfxheight)
end

local function state_Disappear(npc)
	local data = npc.data
	local settings = npc.data._settings
	local config = NPC.config[npc.id]
	if config.fall then
		data.sinkSpeed = math.min(data.sinkSpeed + 0.1,config.speed*settings.speed*3)
		npc.speedY = data.sinkSpeed
		if npc.y+(config.shaftheight-config.gfxheight) > data.startY then
			npc.y = data.startY
			data.state = 0
			data.sinkSpeed = 0
			data.switchtime = lunatime.tick() + settings.waitTime
			npc.friendly = true
		end
	else
		npc.speedY = math.sin(lunatime.tick()/6)
		data.spoutbottom = math.max(math.lerp(npc.y-(config.shaftheight-config.gfxheight),data.startY-(config.shaftheight-config.gfxheight),(data.switchtime - lunatime.tick())/data.bottommovespeed),npc.y-(config.shaftheight-config.gfxheight))
		if nextState(npc) then
			data.state = 0
			data.switchtime = lunatime.tick() + settings.waitTime
			npc.friendly = true
		end
	end
end

states = {
[0] = function(x) state_PreRise(x) end,
[1] = function(x) state_Rising(x) end,
[2] = function(x) state_Peak(x) end,
[3] = function(x) state_Disappear(x) end
}

function spout.onTickNPC(v)
	local data = v.data
	local settings = v.data._settings
	local config = NPC.config[v.id]
	
	if not data.initialized then
		data.state = 0
		data.startY = v.y
		data.spoutbottom = data.startY
		data.bottommovespeed = 0
		data.switchtime = lunatime.tick() + settings.waitTime
		if config.fall then data.sinkSpeed = 0 end
		if not config.shaftheight then config.shaftheight = npcutils.gfxheight(v) end
		if not config.tailheight then config.tailheight = npcutils.gfxheight(v) end
		data.initialized = true
	end

	if config.lava or config.forcerise and not v.friendly and data.state > 0 then
		if (player.x+player.width > v.x and player.x < v.x+v.width) and (player.y+player.height > v.y and player.y < data.spoutbottom) then
			if config.lava and player.deathTimer <= 0 and not (player.mount == MOUNT_BOOT and player.mountColor == BOOTCOLOR_RED and player.y+player.height < v.y+32) then
				player:kill()
				playSFX(16)
			elseif config.hurt then player:hurt() end
			player.speedY = math.clamp(-5*(config.speed*settings.speed),-20,20)
			if config.resistance > 0 then player.speedX = player.speedX / config.resistance end
		end
		for _,vx in NPC.iterateIntersecting(v.x,v.y+4,v.x+v.width,data.spoutbottom) do
			if ((( NPC.config[vx.id].nogravity == false or NPC.config[vx.id].buoyant) and not NPC.config[vx.id].iscoin) or riseRegister[vx.id] == 1) and riseRegister[vx.id] ~= -1 then
				if config.lava then
					vx:harm(HARM_TYPE_LAVA)
					playSFX(16)
				else
					vx.speedY = math.clamp(-5*(config.speed*settings.speed),-20,20)/config.heavylift -- Go on, use a negative heavylift value. It'd be funny :)
					if config.resistance > 0 then vx.speedX = vx.speedX / config.resistance end
				end
			end
		end
	end
	
	if data.state ~= 3 then data.spoutbottom = data.startY end
	if v.friendly then v:mem(0x138,FIELD_WORD,208) end
	
	states[data.state](v)
	
	applyLayerMovement(v)
end

function spout.onDrawNPC(v)
	local data = v.data
	local config = NPC.config[v.id]
	if data.state == 0 or v.despawnTimer < 170 then
		npcutils.hideNPC(v)
		return
	end
	
	shaftSourceY = npcutils.gfxheight(v)*npcutils.frames(v)
	tailSourceY = shaftSourceY+config.shaftheight*npcutils.frames(v)
	
	if config.foreground then p = -15 else p = -75 end
	for i=0,math.ceil((data.spoutbottom-v.y)/config.shaftheight) do
		h = math.min(config.shaftheight-((v.y+(i*config.shaftheight))-data.spoutbottom)-config.tailheight,config.shaftheight) --Crop the shaft below the tail
		npcutils.drawNPC(v,{priority=p,yOffset=i*config.shaftheight,height=h,sourceY=shaftSourceY+(v.animationFrame*config.shaftheight),frame=0})
	end
	npcutils.drawNPC(v,{priority=p,yOffset=(data.spoutbottom-v.y)+config.tailoffset,height=config.tailheight,sourceY=tailSourceY+(v.animationFrame*config.tailheight),frame=0})
	npcutils.drawNPC(v,{priority=p,yOffset=config.headoffset})
	npcutils.hideNPC(v)
end

return spout