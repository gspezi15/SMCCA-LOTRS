local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local imagic = require("imagic")

local wildPiranha = {}

local wildPiranhaID = {}

local wildPiranhaParams = {}

local sharedSettings = {
	activerange = 180, --Active range for regular Wild Piranha, Wild Ptooie Piranha is unaffacted
	
	bitesfx  = "piranha-plant.ogg", -- Idle Biting sfx, can be either filename or SMBX internal ID. Comment this to not play any sounds
	deadsfx  = "piranha-plant-defeat.ogg", -- Defeated sfx, can be either filename or SMBX internal ID. Comment this to not play any sounds
	
	--stalkID = 751 --npcID of the Wild Piranha Plant stalk/bulb. Used by both type of Wild Piranhas. Default being WildPiranhaID-1 (The first npc ID in this set) Uncomment this and change manually otherwise
}
function wildPiranha.registerCommonHarmTypes(id)
	npcManager.registerHarmTypes(id,
		{
			HARM_TYPE_NPC,
			HARM_TYPE_SWORD
		}, 
		{
		}
	);
end

--Register events
function wildPiranha.onInitAPI()
	registerEvent(wildPiranha, "onNPCHarm")
end

function wildPiranha.register(id, isceiling, angmin, angmax,stalkID)
	wildPiranhaID[id] = true
	
	local param = {}
	param.isceiling = isceiling;
	param.angmin = angmin;
	param.angmax = angmax;
	param.stalkID = sharedSettings.stalkID or stalkID
	wildPiranhaParams[id] = param;
	
	npcManager.registerEvent(id, wildPiranha, "onTickNPC")
	npcManager.registerEvent(id, wildPiranha, "onTickEndNPC")
	npcManager.registerEvent(id, wildPiranha, "onDrawNPC")
	
	npcManager.setNpcSettings(table.join(sharedSettings, {id=id}));
end

--Custom local definitions below
local STATE_DORMANT = 0
local STATE_ACTIVE = 1

local DEGTORAD = math.pi/180
local RADTODEG = 180/math.pi

local DOUBLEPI = math.pi*2
local HALFPI = math.pi*0.5

--Sprites Drawing Logic tweaked from Basegame Grrrol AI
function drawNPCFrame(id, frame, x, y, angle,scale)
	local settings = npcManager.getNpcSettings(id)
	local priority = -45
	
	frame = frame or 0
	
	if settings.foreground then
		priority = -15
	end
	imagic.Draw{
		texture = Graphics.sprites.npc[id].img,
		width = settings.gfxwidth*scale,
		height = settings.gfxheight*scale,
		sourceWidth = settings.gfxwidth,
		sourceHeight = settings.gfxheight,
		sourceY = frame * settings.gfxheight,
		scene = true,
		x = x + settings.width  * 0.5,
		y = y + settings.height * 0.5,
		rotation = angle,
		align = imagic.ALIGN_CENTRE,
		priority = -45
	}
end

function wildPiranha.onDrawNPC(v)
	v.animationFrame = 99999
	
	local data = v.data
	
	if data.state == STATE_DORMANT then return end
	
	local time = data.animationTimer or 0
	local f
	
	local rot = data.rangle or 0
	local sc = data.renderscale or 1
	
	if data.isdying then
		f = 2+math.floor(time/4)%2
	else
		f = math.floor(time/8)%2
	end
	
	drawNPCFrame(v.id, npcutils.getFrameByFramestyle(v, {frame=f}), v.x, v.y, rot*RADTODEG,sc)
end

function wildPiranha.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		--Reset our properties, if necessary
		
		--Despawn Stem
		if data.mystem.isValid then
			data.mystem:kill(HARM_TYPE_OFFSCREEN)
		end
		
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		
		--Don't Move has no effect on these NPC--
		
		data.bitesfx = NPC.config[v.id].bitesfx
		data.deadsfx = NPC.config[v.id].deadsfx
		data.activerange = NPC.config[v.id].activerange or 180
		
		data.playbitesounds = data.bitesfx ~= null
		
		data.state = STATE_DORMANT
		
		data.animationTimer = 0
		data.angle = 0
		
		data.deathcounter   = 0
		
		data.renderscale = 1
		
		data.offx = 0
		data.offy = 0
		
		data.ogwidth = v.width
		
		v.width = 32
		v.height = 32
		
		w = NPC.spawn(wildPiranhaParams[v.id].stalkID,v.x,v.y,v.section,false,false)
		w.data.myhead = v
		w.data.isceiling = wildPiranhaParams[v.id].isceiling
		w.friendly = true
		w.state = STATE_DORMANT
		w.layerObj = v.layerObj --spawn stem in the same layer as head
		
		data.mystem = w
		
		data.ox = v.x
		data.oy = v.y
		
		data.hp = 5
		
		data.ceiloff = 0
		
		if wildPiranhaParams[v.id].isceiling then
			data.ceiloff = 12
			data.ceilangoff = 0
			
			data.basedeadang = -90
		else
			data.ceiloff = -28
			data.ceilangoff = 0
			
			data.basedeadang = 90
		end
		
		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Self-destruct if it's a part of any container or generator (Yoshi also, but since it's noyoshi by default this should not triggered)
		if data.mystem.isValid then
			data.mystem:kill()
		end
		v:kill()
		
	end
	
	local player = npcutils.getNearestPlayer(v)
	
	if data.state == STATE_DORMANT then
	
		v.x = data.ox
		v.y = data.oy
	
		if math.abs((player.x + 0.5 * player.width) - (data.ox + 0.5 * data.ogwidth)) < data.activerange then
			data.state = STATE_ACTIVE
			data.mystem.data.state = STATE_ACTIVE
			
			v.width = 48
			v.height = 48
		end
	
	elseif data.state == STATE_ACTIVE then
		if not data.isdying and math.abs((player.x + 0.5 * player.width) - (data.ox + 0.5 * data.ogwidth)) > data.activerange then
			data.state = STATE_DORMANT
			data.mystem.data.state = STATE_DORMANT
			
			v.width = 32
			v.height = 32
			
			v.x = data.ox
			v.y = data.oy
		end
	end
end

function wildPiranha.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	local param = wildPiranhaParams[v.id]

	if data. state == STATE_ACTIVE then
		if not data.isdying then
			data.animationTimer = data.animationTimer+1
			
			if data.playbitesounds then
				if data.animationTimer%16==0 then
					SFX.play(data.bitesfx)
				end
			end
			
			local aimangle = math.atan2(v.y-player.y,v.x-player.x)
			
			--Update angle only if aimangle is in range
			if aimangle >= param.angmin and aimangle <= param.angmax then
				data.angle = aimangle
			end
		else
			data.deathcounter = data.deathcounter+1
			
			if data.deathcounter<=60 then
		
			data.angle = math.anglelerp(data.angle-0.001,(data.basedeadang-30*data.deaddirection)*DEGTORAD,data.deathcounter/60) -- -0.001 is to prevent weird angle leap at 180
			data.rangle = data.angle
			elseif data.deathcounter>60 then
			
				if data.deadsfx and data.deathcounter==61 then
					SFX.play(data.deadsfx)
				end
				
				data.animationTimer = data.animationTimer+1
				
				if data.renderscale > 0 then
				data.renderscale = data.renderscale-0.03
				else
					if data.mystem.isValid then
						Effect.spawn(10, data.mystem.x, data.mystem.y)
						data.mystem:kill(HARM_TYPE_OFFSCREEN)
					end
					v:kill(HARM_TYPE_OFFSCREEN)
				end
				
			end
		end
		
		if data.angle > HALFPI or data.angle < -HALFPI then
				v.direction = 1
				data.rangle = data.angle-math.pi
			else
				v.direction = -1
				data.rangle = data.angle
			end
		
		v.x = data.ox -6 + 32*data.renderscale*math.cos(data.angle+math.pi)+data.offx
		v.y = data.oy + 16*data.renderscale*math.sin(data.angle+math.pi)+data.offy+data.ceiloff
	end
	
	--Update Stem Position
	if data.mystem ~= nil and data.mystem.isValid then
		data.ox = data.mystem.x
		data.oy = data.mystem.y
	end
end

function wildPiranha.onNPCHarm(eventObj, v, killReason, culprit)
	if not wildPiranhaID[v.id] then return end
	
	local data = v.data
	
	if data.state == STATE_DORMANT then
		if data.mystem.isValid then
				Effect.spawn(10, data.mystem.x, data.mystem.y)
				data.mystem:kill(HARM_TYPE_OFFSCREEN)
		end
		return
	end
	
	--Fireball
	if culprit then
		if culprit.__type == "NPC" and culprit.id == 13 then
				data.hp = data.hp - 1
				
				if data.hp > 0 then
					SFX.play(9)
					eventObj.cancelled = true
					return
				end
		end
		
		--Adjust Dying Direction
		if culprit.speedX > 0 or (culprit.speedX==0 and culprit.x < v.x) then
			v.direction = -1
		else
			v.direction = 1
		end
	end
	
	--Dead
	SFX.play(9)
	v.friendly = true
	if data.mystem.isValid then
		data.mystem.friendly = true
	end
	
	data.isdying = true
	
	
	
	
	data.offx = -4*v.direction
	if wildPiranhaParams[v.id].isceiling then
		data.deaddirection = -v.direction
		data.offy = -2
	else
		data.deaddirection = v.direction
		data.offy = 2
	end
	
	
	
	data.animationTimer = 0
	
	if killReason==HARM_TYPE_NPC or killReason==HARM_TYPE_SWORD then
		eventObj.cancelled = true;
		if culprit then
			culprit:kill()
		end
	end
	

end

--[[========================================
Wild Ptooie Section
===========================================]]
function wildPiranha.register_Ptooie(id, isceiling,projectileID,stalkID)
	wildPiranhaID[id] = true
	
	local param = {}
	param.isceiling = isceiling;
	param.projectileID = projectileID;
	param.stalkID = sharedSettings.stalkID or stalkID
	wildPiranhaParams[id] = param;
	
	npcManager.registerEvent(id, wildPiranha, "onTickNPC", "onTickNPC_Ptooie")
	--npcManager.registerEvent(id, wildPiranha, "onTickEndNPC")
	npcManager.registerEvent(id, wildPiranha, "onDrawNPC" , "onDrawNPC_Ptooie")
	
	npcManager.setNpcSettings(table.join(sharedSettings, {id=id}));
end

function wildPiranha.onTickNPC_Ptooie(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		--Reset our properties, if necessary
		
		--Despawn Stem
		if data.mystem.isValid then
			data.mystem:kill(HARM_TYPE_OFFSCREEN)
		end
		
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		
		--Don't Move has no effect on these NPC--
		if v.dontMove then
			v.dontMove = false
		end
		
		data.splitsfx = NPC.config[v.id].splitsfx
		data.deadsfx = NPC.config[v.id].deadsfx
		
		data.playsplitsounds = data.splitsfx ~= null
		
		data.normalangle = (NPC.config[v.id].normalangle or 45) * DEGTORAD
		data.specialangle = (NPC.config[v.id].specialangle or 80) * DEGTORAD
		data.baseangle = 0
		
		if v.direction==1 then
			data.normalangle = math.pi - data.normalangle
			data.specialangle = math.pi - data.specialangle
			data.baseangle = math.pi
		end
		
		data.state = STATE_ACTIVE
		data.counter = 0
		data.deathcounter = 0
		
		data.openmouthtime = 0
		
		data.renderscale = 1
		
		data.offx = 0
		data.offy = 0
		data.ceiloff = -26
		
		data.basedeadang = 90
		
		w = NPC.spawn(wildPiranhaParams[v.id].stalkID,v.x,v.y,v.section,false,false)
		w.data.myhead = v
		w.data.isceiling = wildPiranhaParams[v.id].isceiling
		w.friendly = true
		w.data.state = STATE_ACTIVE
		w.layerName = v.layerName --spawn stem in the same layer as head
		
		data.mystem = w
		
		data.ox = v.x
		data.oy = v.y
		
		data.hp = 15
		
		data.angle = data.baseangle
		
		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Self-destruct if it's a part of any container or generator (Yoshi also, but since it's noyoshi by default this should not triggered)
		if data.mystem.isValid then
			data.mystem:kill()
		end
		v:kill()
		
	end
	
	if not data.isdying then
	
		--Angle Change
		if data.counter > 30 and data.counter < 75 then
			data.angle = math.anglelerp(data.baseangle,data.normalangle,(data.counter-30)/45)
		elseif data.counter > 180 and data.counter <= 210 then
			data.angle = math.anglelerp(data.normalangle,data.specialangle,(data.counter-180)/30)
		elseif data.counter > 240 and data.counter <= 300 then
			data.angle = math.anglelerp(data.specialangle,data.baseangle,(data.counter-240)/60)
		end
		
		--Split
		if data.counter >= 90 and data.counter <= 210 then
			if (data.counter-90)%60==0 then
			
				if data.playsplitsounds then
					SFX.play(data.splitsfx)
				end
			
				data.openmouthtime = 15
				
				local w = NPC.spawn(wildPiranhaParams[v.id].projectileID,v.x,v.y,v.section,false,false)
				if data.counter==210 then
					w.data.angle = data.specialangle
				else
					w.data.angle = data.normalangle
				end
				w.layerName = "Spawned NPCs"
				
			end
		elseif data.counter > 390 then
			data.counter = 0
		end
	
		data.counter = data.counter+1
		
		if data.openmouthtime > 0 then
			data.openmouthtime = data.openmouthtime-1
		end
	
	else
		
		--Damaged/Death Sequence
		data.deathcounter = data.deathcounter+1
			
			data.openmouthtime = 1
			
			if data.deathcounter==1 then
				data.hp = data.hp-5
			end
			
			if data.deathcounter<=60 then
		
			data.angle = math.anglelerp(data.angle-0.001,(data.basedeadang-30*data.deaddirection)*DEGTORAD,data.deathcounter/60) -- -0.001 is to prevent weird angle leap at 180
			
			elseif data.deathcounter>60 then
				
			
				--Death
				if data.hp <=0 then
					
					if data.deadsfx and data.deathcounter==61 then
						SFX.play(data.deadsfx)
					end
					
					data.animationTimer = data.animationTimer+1
					
					if data.renderscale > 0 then
						data.renderscale = data.renderscale-0.03
					else
						if data.mystem.isValid then
							Effect.spawn(10, data.mystem.x, data.mystem.y)
							data.mystem:kill(HARM_TYPE_OFFSCREEN)
						end
						v:kill(HARM_TYPE_OFFSCREEN)
					end
				
				else
					data.openmouthtime = 0
					
					data.angle = math.anglelerp((data.basedeadang-30*data.deaddirection)*DEGTORAD,data.baseangle,(data.deathcounter-60)/60)
					
					if data.deathcounter>120 then
						data.isdying = false
						v.friendly = false
						data.deathcounter = 0
						data.counter = 0
					end
				
				end
				
			end
		
	end
	
	
	if data.angle > HALFPI or data.angle < -HALFPI then
		v.direction = 1
		data.rangle = data.angle-math.pi
	else
		v.direction = -1
		data.rangle = data.angle
	end
		
	
	--Update Stem Position
	if data.mystem ~= nil and data.mystem.isValid then
		data.ox = data.mystem.x
		data.oy = data.mystem.y
	end
	
	v.x = data.ox -6 + 32*data.renderscale*math.cos(data.angle+math.pi)+data.offx
	v.y = data.oy + 16*data.renderscale*math.sin(data.angle+math.pi)+data.offy+data.ceiloff
	
end

function wildPiranha.onDrawNPC_Ptooie(v)
	v.animationFrame = 99999
	
	local data = v.data
	
	--If data is not initialized, everything is null so don't draw
	if not data.initialized then return end
	
	if data.state == STATE_DORMANT then return end
	
	local time = data.animationTimer or 0
	local f
	
	if data.openmouthtime > 0 then
		f = 0
	else
		f = 1
	end
	
	
	if data.isdying and data.hp<=0 then
		f = 6+math.floor(time/4)%2
	elseif data.hp<=5 then
		f = f+4
	elseif data.hp<=10 then
		f = f+2
	end
	
	local rot = data.rangle or 0
	local sc = data.renderscale or 1
	
	drawNPCFrame(v.id, npcutils.getFrameByFramestyle(v, {frame=f}), v.x, v.y, rot*RADTODEG,sc)
end

return wildPiranha