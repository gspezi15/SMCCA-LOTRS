return {
	init = function(v, data, settings)
		local env = {}
		local fields = {}
		
		env.npc = function()
			return v
		end
		
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
		
		local function defineData2(name, realName)
			fields[realName] = {
				set = function(val)
					data[name] = val
				end,
				
				get = function()
					return data[name]
				end
			}
		end
		
		defineData('timer', 't')
		
		defineData('frame')
		defineData('frameTimer')
		defineData('frameSpeed')
		defineData('frameStyle')
	
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
	end
}