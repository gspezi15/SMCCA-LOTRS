local bossHp = {}

local textplus = require 'textplus'
local font = textplus.loadFont("textplus/font/2.ini")

local queqe = {}

do
	local borderTexture = Graphics.loadImageResolved 'bossNPC/kirbyBox.png'
	local barTexture = Graphics.loadImageResolved 'bossNPC/kirbyBar.png'
	local gradientTexture = Graphics.loadImageResolved 'bossNPC/kirbyBarGradient.png'
	
	local font = textplus.loadFont("textplus/font/6.ini")

	bossHp[3] = function(dy, settings) -- kirby
		local w = barTexture.width
		local h = barTexture.height
	
		local x = 800 - w - 16
		local y = (600 - h - 8) + dy

		Graphics.drawBox{texture = barTexture, x = x, y = y, priority = 4}
			
		local percent = math.floor((settings.hp / settings.maxHp) * 100)
		
		Graphics.drawBox{texture = gradientTexture, x = x + 4, y = y + 4, width = percent, priority = 4}	
		
		local name = settings.name
		if name then
			textplus.print{text = name, x = x + 4, y = y - 16, xscale = 2, yscale = 2, font = font, priority = 4}
		end
		
		local icon = settings.icon
		if icon then
			local x = x - borderTexture.width
			local y = y - borderTexture.height * 0.25
			
			Graphics.drawBox{texture = borderTexture, x = x, y = y, priority = 4}
			Graphics.drawBox{texture = icon, x = x + 4, y = y + 4, sourceWidth = 32, sourceHeight = 32, priority = 4}
		end
		
		return -(h + 16)
	end
end

bossHp[2] = function(dy, settings) -- simple
	local w = 148
	local h = 28
	
	local x = 800 - w - 8
	local y = (600 - h - 8) + dy
	
	Graphics.drawBox{
		x = x,
		y = y,
		width = w,
		height = h,
		
		color = Color.black .. 0.5,
		priority = 4,
	}
	
	local icon = settings.icon

	if icon then
		Graphics.drawBox{
			texture = icon,
			
			x = x,
			y = y,
			sourceWidth = 32,
			sourceHeight = 32,
			
			priority = 4,
		}
		
		x = x + 32
	end
	
	local name = settings.name
	
	if name then
		textplus.print{
			text = name,
			
			x = x + 2,
			y = y - 4,
			
			xscale = 2,
			yscale = 2,
			font = font,
			
			priority = 4,
		}
	end
	
	local percent = math.floor((settings.hp / settings.maxHp) * 100)
		
	Graphics.drawBox{
		x = x + 2,
		y = (y + h) - 12,
		width = 100,
		height = 12,
		
		color = Color.black,
		priority = 4,
	}
	
	Graphics.drawBox{
		x = x,
		y = (y + h) - 14,
		width = percent,
		height = 12,
		
		color = Color.red,
		priority = 4,
	}
	
	textplus.print{
		text = (percent .. '%'),
		
		x = x,
		y = (y + h) - 12,
		
		font = font,
		xscale = 2,
		yscale = 2,
		priority = 4,
	}
	
	return -(h + 12) 
end

function bossHp.draw(style, settings)
	local draw
	
	if type(style) ~= 'function' then
		draw = bossHp[style]
	else
		draw = style
	end
	
	if draw then
		table.insert(queqe, {f = draw, settings = settings})
	end
end

function bossHp.onDraw()
	local dy = 0
	
	for k,v in ipairs(queqe) do
		local move = v.f(dy, v.settings)
		
		if move then
			dy = dy + move
		end
	end
	
	queqe = {}
end

function bossHp.onInitAPI()
	registerEvent(bossHp, 'onDraw')
end
 
return bossHp