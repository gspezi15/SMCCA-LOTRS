--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local utils = require("npcs/npcutils")
local webi = Shader()
webi:compileFromFile(nil, "wave.frag")
--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local settings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	
	

	

	

	--Define custom properties below
	rad = {16,30,45,45},
	scl = {0.5,1,1.5,2},
	vel = {1,1.5,2,2.5}
}

--Applies NPC settings
npcManager.setNpcSettings(settings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.


--Custom local definitions below


--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onPostNPCKill")
	

end



	








function sampleNPC:onDrawNPC()
	local data = self.data

	if not data.init then
		data.getValue = RNG.randomInt(1,4)
		data.init = true
	end

 
	--Make friends
	self.friendly = true

	if data.part == nil then
		data.part = Particles.Emitter(0,0, Misc.resolveFile("particles/p_flame_large.ini"))
	end
	if data.partSmall == nil then
		data.partSmall = Particles.Emitter(0,0, Misc.resolveFile("particles/p_flame_small.ini"))
	end
	if data.getValue == 3 or data.getValue == 4 then
		data.part.x = self.x+(self.width*0.5) - 32
	   data.part.y = self.y+(self.height*0.5)
	   data.part:Draw(-65)
	else
		data.partSmall.x = self.x
		data.partSmall.y = self.y
		data.partSmall:Draw(-65)
	end
	

	
	

	if data.sprite == nil then
		data.sprite = data.sprite or Sprite{texture = Graphics.sprites.npc[self.id].img,pivot = Sprite.align.CENTRE,frames = 1}
        data.sprite.y = camera.bounds.top 
	end
	data.col = data.col or Colliders.Circle(0,0,settings.rad[data.getValue])
	
    data.sprite.y = data.sprite.y + 1.5
    self.y = data.sprite.y
	data.col.x,data.col.y = self.x,self.y
	data.sprite.x,data.sprite.y = self.x,self.y
	
	
	--collision possibilities

	local getShell = Colliders.getColliding{a=NPC.SHELL, atype = Colliders.NPC, b = data.col}
	local getProj = Colliders.getColliding{a=NPC.UNHITTABLE, atype = Colliders.NPC, b = data.col}
	local getBlocks = Colliders.getColliding{a=Block.SOLID, atype = Colliders.BLOCK, b = data.col}
	

	

	for _,b in ipairs(getBlocks) do
		if b.contentID ~= 0 then

			
			b:hit()
			self:kill(HARM_TYPE_NPC)
		elseif b.id == 4 then
			b:remove(true)
			self:kill(HARM_TYPE_NPC)
		end
		
		
		
	end

	for _,sh in ipairs(getShell) do
        if sh:mem(0x136,FIELD_BOOL) then --projectile mode
            self:kill(HARM_TYPE_NPC)
		end
    end

	for _,p in ipairs(getProj) do
		SFX.play(3)
		p:kill()
	end
	
	
	local transfm = data.sprite.transform
	transfm.rotation = transfm.rotation + settings.vel[data.getValue]
	transfm.scale = vector.v2(settings.scl[data.getValue],settings.scl[data.getValue])


	if Colliders.collide(data.col,player) then
		player:harm()
	end
    


	data.sprite:draw{sceneCoords=true,priority=-45,shader=webi,uniforms={iTime=lunatime.drawtick(),intensity = 0.4, iResolution = {data.sprite.width*2,data.sprite.height*2,1},iMask=Graphics.sprites.npc[self.id].img}}


	utils.hideNPC(self)


end



function sampleNPC.onPostNPCKill(self,harm)
	if harm ~= HARM_TYPE_NPC or self.id ~= npcID then return end

	SFX.play(4)
	Animation.spawn(1,self.x,self.y)

end




--Gotta return the library table!
return sampleNPC