--------------------------------------------------
-- Level code
-- Created 21:49 2021-7-28



-- Run code on level start
local utils = require("npcs/npcutils")
local bUtil = require("blocks/blockutils")
function onStart()
    --Your code here
end

-- Run code every frame (~1/65 second)
-- (code will be executed before game logic will be processed)
local cooldown = 0






local function colBlock()
  for _,b in Block.iterateIntersecting(player.x,player.y,player.x + player.width * 0.5,player.y + player.height * 0.5) do
    if b.id == 25 then
      return true
    end
  end
  return false

end
local sin = 0
function onTick()
  if colBlock() then
    cooldown = cooldown + 1
    if cooldown >= 200  then
      SFX.play(42)
      NPC.spawn(778,RNG.randomInt(camera.bounds.left,camera.bounds.right),camera.bounds.top + 32,player.section,true,true)
      cooldown = 0
     end
    
  end


  


  
  


  

  

  
  
  
  

  
end


function onDraw()
 
  for _,b in Block.iterate(25) do
     b.isHidden = true
 end

    for _,v in ipairs(NPC.get(589)) do
        local data = v.data
        data.rot = data.rot or 0
        data.podobo = Sprite{image = Graphics.sprites.npc[589].img,frames=2,align=Sprite.align.CENTRE}
        data.podobo.x = v.x + v.width * 0.5
        data.podobo.y = v.y + v.height * 0.5
        data.Frames = math.floor(lunatime.tick() / 8) % 2 + 1
        
        utils.hideNPC(v)
        if v.speedY > 0 then
          data.rot = math.clamp(data.rot + 10,0,180)
          data.podobo.transform.rotation = data.rot
        else
          data.rot = 0
        end
        
        
          
        data.podobo:draw{frame = data.Frames,priority = -76,sceneCoords = true}
    
        
      end

   
   

    --Graphics.drawScreen{priority = 10, texture = wabo, shader = webi, uniforms = {iTime=lunatime.drawtick(), iResolution = {800,600,1}}}
  
    
  


end



-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(eventName)
    --Your code here
end

