return {
	init = function(v, data, settings)
		local env = {}
		
		env.loadResolved = function(path, ...)
			return loadfile(Misc.resolveFile(path), ...)
		end
		
		env.soundPlay = SFX.play
		env.spawn = NPC.spawn
		env.wait = Routine.waitFrames
		
		env.loadTexture = Graphics.loadImageResolved
		
		env.texture = function(n)
			data.sprite.texture = Graphics.loadImageResolved(n)
		end
		
		env.addSprite = function(spr)
			data.sprites = data.sprites or {}
			
			local v = {obj = Sprite(spr)}
			
			table.insert(data.sprites, v)
			return v
		end
		
		env.clearSprite = function(ind)
			if not data.sprites then return end
			
			if type(ind) == 'number' then
				table.remove(data.sprites, ind)
			else
				for k,spr in ipairs(data.sprites) do
					if spr == ind then
						table.remove(data.sprites, k)
						break
					end
				end
			end
		end
		
		env.hide = function()
			data.spriteHidden = true
		end
		
		env.show = function()
			data.spriteHidden = false
		end
		
		env.wave = function(speed)
			local speed = speed or 1
			
			v.speedY = math.sin(lunatime.tick() / 8) * speed
		end
		
		env.plr = function()
			local x = v.x + v.width * 0.5
			local y = v.y + v.height * 0.5
			
			return Player.getNearest(x, y)
		end
		
		env.facePlr = function()
			local p = env.plr()
			
			if p.x + p.width * 0.5 > v.x + v.width * 0.5 then
				v.direction = 1
			else
				v.direction = -1
			end
		end
		
		env.follow = function(speed)
			local speed = speed or 0.1
			local p = env.plr()
			
			if p.x + p.width * 0.5 > v.x + v.width * 0.5 then
				v.speedX = v.speedX + speed
			else
				v.speedX = v.speedX - speed
			end
		end
		
		env.shoot = function(speed, ...)
			local speed = speed or 2
			local bullet = NPC.spawn(...)
			
			local p = env.plr()
			
			local endX = v.x + v.width * 0.5
			local endY = v.y + v.height * 0.5
			
			local startX = p.x + p.width * 0.5
			local startY = p.y + p.height * 0.5
			
			local angle = math.atan2((startY - endY), (startX - endX))
			
			bullet.speedX = speed * math.cos(angle)
			bullet.speedY = speed * math.sin(angle)
			
			return bullet
		end
		
		env.jump = function(speed)
			if v.collidesBlockBottom then
				v.speedY = -speed
			end
		end
		
		env.move = function(speed)
			v.speedX = speed * v.direction
		end
		
		env.stop = function(f)
			data.stop = f
		end
		
		env.stopAttack = function(maxTimer, f)
			if not maxTimer then
				return true
			end
			
			data.attackTimer = data.attackTimer + 1
			if data.attackTimer >= maxTimer then
				if f then
					f()
				end
				
				return true
			end
		end
		
		env.addAttack = function(phases, pos, f)
			phases[pos] = phases[pos] or {}
			
			table.insert(phases[pos], f)
		end
		
		env.setCondition = function(phases, pos, cond)
			phases[pos] = phases[pos] or {}
			
			phases[pos].condition = cond
		end
		
		local fields = {}
		
		fields.t = {
			get = function()
				return data.timer
			end
		}
		
		fields.npc = {
			get = function()
				return v
			end
		}
		
		fields.sprite = {
			get = function()
				return data.sprite
			end,
			
			set = function(val)
				data.sprite = Sprite(val)
			end,
		}
		
		fields.totalFrames = {
			get = function()
				local frames = data.frames
				
				if data.frameStyle == 1 then
					frames = frames + frames
				elseif data.frameStyle == 2 then
					frames = (frames + frames) * 2
				end
				
				return frames
			end,
		}
		
		local function define(name)
			fields[name] = {
				set = function(val)
					v[name] = val
				end,
				
				get = function()
					return v[name]
				end
			}
		end
		
		local function defineData(name)
			fields[name] = {
				set = function(val)
					data[name] = val
				end,
				
				get = function()
					return data[name]
				end
			}
		end
		
		define('collidesBlockBottom')
		define('collidesBlockTop')
		define('collidesBlockLeft')
		define('collidesBlockRight')
		
		define('direction')
		define('speedX')
		define('speedY')
		define('x')
		define('y')
		define('width')
		define('height')
		define('data')
		
		defineData('hp')
		defineData('maxHp')
			
		defineData('nogravity')
		defineData('frames')
		defineData('frameTimer')
		defineData('frameSpeed')
		defineData('frameStyle')
		
		fields.centerX = {
			get = function()
				return v.x + v.width * 0.5
			end
		}
		
		fields.centerY = {
			get = function()
				return v.y + v.height * 0.5
			end
		}
		
		setmetatable(env, {
			__index = function(self, key)
				if fields[key] and fields[key].get then
					return fields[key].get()
				end
				
				return _G[key]
			end, 
			
			__newindex = function(self, key, val)
				if fields[key] and fields[key].set then
					return fields[key].set(val)
				end
				
				_G[key] = val
			end
		})
		
		return env
	end
}