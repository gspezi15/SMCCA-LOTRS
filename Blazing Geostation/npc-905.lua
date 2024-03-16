--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local utils = require("npcs/npcutils")
--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 128,
	gfxwidth = 128,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 32,
	--Frameloop-related
	frames = 2,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = true,
	npcblocktop = true, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = true,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
	hp = 3,
	effectExplosion1ID = 950,
	effectExplosion2ID = 952,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
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

--Custom local definitions below
local STATE_CEILING = 0
local STATE_PULSE = 1
local STATE_FALLING = 2
local STATE_LANDED = 3
local STATE_RISING = 4
local STATE_BARRAGE = 5
local STATE_BOMBS = 6
local STATE_SHOWER = 7
local STATE_KILL = 8
local shoot = Misc.resolveFile("Missile Deploy.wav")
local shower = Misc.resolveFile("Machine Gun-ish.wav")
local lob = Misc.resolveFile("Missile.wav")
local stomp = Misc.resolveFile("Mech Stomp.wav")
local rise = Misc.resolveFile("Mech Rising.wav")
local ready = Misc.resolveFile("Machine Noise.wav")
local bombs = Misc.resolveFile("Small Explosion.wav")
local whoosh = Misc.resolveFile("Small Rocket Woosh.wav")
local hit = Misc.resolveFile("s3k_damage.ogg")
local explode = Misc.resolveFile("s3k_detonate.ogg")
local bigexplode = Misc.resolveFile("Explosion 2.wav")
--Register events
function sampleNPC.onInitAPI()
	--npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onDrawNPC(v)
	local data = v.data
	local config = NPC.config[v.id]
	utils.restoreAnimation(v)
	horizontal = utils.getFrameByFramestyle(v, {
		frames = 1,
		gap = 1,
		offset = 0
	})
	diagonal = utils.getFrameByFramestyle(v, {
		frames = 1,
		gap = 0,
		offset = 1
	})

	if v.invisibleharm == false then
		if v.diagonal == false then
			v.animationFrame = horizontal
		else
			v.animationFrame = diagonal
		end
	else
		v.animationFrame = -50
	end
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end
	local p = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		v.state = STATE_CEILING
		v.idletimer = 0
		v.loadtimer1 = 0
		v.loadtimer2 = 0
		v.loadtimer3 = 0
		v.decision = 0
		v.diagonal = false
		v.yspeed = 0
		v.harmframe = 0
		v.harmtimer = 120
		v.invisibleharm = false
		v.harmed = false
		v.hp = sampleNPCSettings.hp
		v.idletime = RNG.randomInt(150, 240)
		if p.x < v.x + 0.5 * v.width then v.direction = -1; end;
		if p.x > v.x + 0.5 * v.width then v.direction = 1; end;
	end
	if v.harmed == true then
		v.harmtimer = v.harmtimer - 1
		v.harmframe = v.harmframe + 1
		if v.harmframe == 4 then
			v.harmframe = 0
		end
		if v.harmframe > 2 then
			v.invisibleharm = true
		else
			v.invisibleharm = false
		end
		if v.harmtimer == 0 then
			v.harmtimer = 120
			v.harmframe = 0
			v.harmed = false
		end
	end
	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
		v.state = STATE_CEILING
		v.idletimer = 0
		return
	end
	if v.state == STATE_CEILING then
		v.speedX = 3 * v.direction
		v.speedY = 0
		v.idletimer = v.idletimer + 1
		if v.idletimer == v.idletime then
			v.decision = RNG.randomInt(1, 6)
			v.idletimer = 0
			v.idletime = RNG.randomInt(150, 240)
			if v.decision == 1 then
				v.state = STATE_PULSE
			elseif v.decision == 2 then
				v.state = STATE_FALLING
			elseif v.decision == 3 then
				v.state = STATE_SHOWER
			elseif v.decision == 4 then
				v.state = STATE_BOMBS
			elseif v.decision == 5 then
				v.speedY = RNG.randomInt(3, 5)
				v.state = STATE_BARRAGE
				v.idletime = RNG.randomInt(240, 360)
			elseif v.decision == 6 then
				v.state = STATE_CEILING
				local rinka = NPC.spawn(210, v.x + 16, v.y + 80, player.section, false, false)
				rinka.layerName = "Spawned NPCs"
				rinka.speedY = 3
				Animation.spawn(10, v.x + 16, v.y + 80)
				SFX.play(22)
				v.state = STATE_CEILING
				if p.x < v.x + 0.5 * v.width then v.direction = -1; end;
				if p.x > v.x + 0.5 * v.width then v.direction = 1; end;
			end
		end
	elseif v.state == STATE_PULSE then
		v.speedX = 0
		v.diagonal = true
		v.idletimer = v.idletimer + 1
		v.loadtimer1 = v.loadtimer1 + 1
		if v.loadtimer1 == 5 and v.idletimer <= 120 then
			v.loadtimer1 = 0
			local fire1 = NPC.spawn(348, v.x + 16, v.y + 80, player.section, false, false)
			local fire2 = NPC.spawn(348, v.x - 24, v.y + 48, player.section, false, false)
			local fire3 = NPC.spawn(348, v.x + 56, v.y + 48, player.section, false, false)
			fire1.speedX = 0
			fire2.speedX = -3
			fire3.speedX = 3
			fire1.speedY = 6
			fire2.speedY = 5
			fire3.speedY = 5
			fire1.layerName = "Spawned NPCs"
			fire2.layerName = "Spawned NPCs"
			fire3.layerName = "Spawned NPCs"
			Animation.spawn(10, v.x + 16, v.y + 80)
			Animation.spawn(10, v.x - 24, v.y + 48)
			Animation.spawn(10, v.x + 56, v.y + 48)
			SFX.play(shoot)
		end
		if v.idletimer == 150 then
			v.idletimer = 0
			v.loadtimer1 = 0
			local bomb = NPC.spawn(134, v.x + 16, v.y + 80, player.section, false, false)
			bomb.speedY = 5
			bomb.layerName = "Spawned NPCs"
			Animation.spawn(10, v.x + 16, v.y + 80)
			SFX.play(lob)
			v.state = STATE_CEILING
			if p.x < v.x + 0.5 * v.width then v.direction = -1; end;
			if p.x > v.x + 0.5 * v.width then v.direction = 1; end;
		end
	elseif v.state == STATE_FALLING then
		v.speedX = 0
		v.speedY = 6
		if v.collidesBlockBottom then
			v.speedY = 0
			v.state = STATE_LANDED
			v.idletimer = 0
			defines.earthquake = 10
			SFX.play(stomp)
			Animation.spawn(10, v.x - 16, v.y + 32)
			Animation.spawn(10, v.x + 32, v.y + 32)
		end
	elseif v.state == STATE_LANDED then
		v.diagonal = false
		v.idletimer = v.idletimer + 1
		v.loadtimer1 = v.loadtimer1 + 1
		v.loadtimer2 = v.loadtimer2 + 1
		if v.loadtimer1 == 60 then
			v.loadtimer1 = 0
			local firel = NPC.spawn(85, v.x - 32, v.y + 24, player.section, false, false)
			local firer = NPC.spawn(85, v.x + 64, v.y + 24, player.section, false, false)
			firel.speedX = -3
			firer.speedX = 3
			firel.direction = -1
			firer.direction = 1
			firel.layerName = "Spawned NPCs"
			firer.layerName = "Spawned NPCs"
			Animation.spawn(10, v.x - 32, v.y + 16)
			Animation.spawn(10, v.x + 64, v.y + 16)
			SFX.play(16)
		end
		if v.loadtimer2 == 150 then
			v.loadtimer2 = 0
			Animation.spawn(10, v.x + 16, v.y -64)
			local rinka = NPC.spawn(210, v.x + 16, v.y - 64, player.section, false, false)
			rinka.layerName = "Spawned NPCs"
			rinka.speedY = -2.5
			SFX.play(lob)
		end
		if v.idletimer == 360 then
			v.idletimer = 0
			v.loadtimer1 = 0
			v.loadtimer2 = 0
			v.state = STATE_RISING
			SFX.play(rise)
		end
	elseif v.state == STATE_RISING then
		v.speedY = -2.75
		if v.collidesBlockUp then
			v.state = STATE_CEILING
			local bomb = NPC.spawn(134, v.x + 16, v.y + 80, player.section, false, false)
			bomb.speedY = 5
			bomb.layerName = "Spawned NPCs"
			Animation.spawn(10, v.x + 16, v.y + 80)
			SFX.play(lob)
		end
	elseif v.state == STATE_SHOWER then
		v.idletimer = v.idletimer + 1
		v.loadtimer1 = v.loadtimer1 + 1
		if v.loadtimer1 == 5 then
			Animation.spawn(10, v.x + 16, v.y -64)
			local projectile = NPC.spawn(276, v.x + 16, v.y - 64, player.section, false, false)
			projectile.layerName = "Spawned NPCs"
			projectile.speedX = RNG.random(-8, 8)
			projectile.speedY = RNG.random(-2, -6)
			SFX.play(shower)
			v.loadtimer1 = 0
		end
		if v.idletimer == 150 then
			v.idletimer = 0
			v.idletime = 330
			v.loadtimer1 = 0
			v.state = STATE_CEILING
		end
	elseif v.state == STATE_BOMBS then
		v.idletimer = v.idletimer + 1
		v.speedX = 0
		v.diagonal = true
		if v.idletimer == 1 then
			SFX.play(ready)
		end
		if v.idletimer == 60 then
			v.idletimer = 0
			v.state = STATE_CEILING
			local bomb1 = NPC.spawn(906, v.x + 16, v.y + 80, player.section, false, false)
			local bomb2 = NPC.spawn(902, v.x - 24, v.y + 48, player.section, false, false)
			local bomb3 = NPC.spawn(902, v.x + 56, v.y + 48, player.section, false, false)
			bomb1.speedX = 0
			bomb2.speedX = -3
			bomb3.speedX = 3
			bomb1.speedY = 6
			bomb2.speedY = 5
			bomb3.speedY = 5
			bomb1.layerName = "Spawned NPCs"
			bomb2.layerName = "Spawned NPCs"
			bomb3.layerName = "Spawned NPCs"
			Animation.spawn(10, v.x + 16, v.y + 80)
			Animation.spawn(10, v.x - 24, v.y + 48)
			Animation.spawn(10, v.x + 56, v.y + 48)
			SFX.play(bombs)
		end
	elseif v.state == STATE_BARRAGE then
		v.idletimer = v.idletimer + 1
		v.loadtimer1 = v.loadtimer1 + 1
		if v.yspeed == 0 then v.yspeed = 4 end
		v.speedY = v.yspeed
		v.diagonal = false
		v.speedX = 1.75 * v.direction
		if v.collidesBlockBottom then
			v.yspeed = -3
		elseif v.collidesBlockUp then
			v.yspeed = 3
		end
		if v.loadtimer1 == 45 then
			v.loadtimer1 = 0
			local firel = NPC.spawn(907, v.x - 32, v.y + 24, player.section, false, false)
			local firer = NPC.spawn(907, v.x + 64, v.y + 24, player.section, false, false)
			firel.speedX = -3
			firer.speedX = 3
			firel.direction = -1
			firer.direction = 1
			firel.layerName = "Spawned NPCs"
			firer.layerName = "Spawned NPCs"
			SFX.play(whoosh)
			Animation.spawn(10, v.x - 32, v.y + 16)
			Animation.spawn(10, v.x + 64, v.y + 16)
		end
		if v.idletimer == v.idletime then
			v.idletimer = 0
			v.speedX = 0
			v.speedY = 0
			v.loadtimer1 = 0
			v.idletime = RNG.randomInt(150, 300)
			v.state = STATE_RISING
		end
	elseif v.state == STATE_KILL then
		v.harmed = true
		v.idletimer = v.idletimer + 1
		if v.idletimer % 16 == 0 then
			SFX.play(explode)
			local a = Animation.spawn(sampleNPCSettings.effectExplosion1ID,v.x+v.width/2,v.y+v.height/2)
			a.x=a.x-a.width/2+RNG.randomInt(-sampleNPCSettings.width/2,sampleNPCSettings.width/2)
			a.y=a.y-a.height/2+RNG.randomInt(-sampleNPCSettings.height/2,sampleNPCSettings.height/2)
		end
		if v.idletimer >= 200 then
			SFX.play(bigexplode)
			local a = Animation.spawn(sampleNPCSettings.effectExplosion2ID,v.x+v.width/2,v.y+v.height/2)
			v:kill(HARM_TYPE_NPC)
			a.x=a.x-a.width/2
			a.y=a.y-a.height/2
		end
	end	
end

function sampleNPC.onNPCHarm(eventObj, v, killReason, culprit)
	local data = v.data
	if v.id ~= npcID then return end
	if v.state == STATE_KILL then eventObj.cancelled = true return end
	if killReason == HARM_TYPE_NPC or HARM_TYPE_PROJECTILE_USED or HARM_TYPE_SWORD then
		if v:mem(0x156,FIELD_WORD) == 0 and v.harmed == false then
			v.hp = v.hp - 1
			SFX.play(hit)
			v.harmed = true
		end
		eventObj.cancelled = true
	else
		eventObj.cancelled = true
		return
	end
	if v.hp <= 0 then
		eventObj.cancelled = true
		v.idletimer = 0
		v.state = STATE_KILL
		v.speedX = 0
		v.speedY = 0
		if v.legacyBoss then
			local ball = NPC.spawn(16, v.x, v.y, v.section)
			ball.x = ball.x + ((v.width - ball.width) / 2)
			ball.y = ball.y + ((v.height - ball.height) / 2)
			ball.speedY = -6
			ball.despawnTimer = 100
			
			SFX.play(20)
		end
	end	
	if v.hp > 0 then
		eventObj.cancelled = true
		v:mem(0x156,FIELD_WORD,60)
	end
end

--Gotta return the library table!
return sampleNPC