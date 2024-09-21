
-- HOW TO USE:
-- 1. Paste this in code:
--------------------------------------------------------------
-- Modules = {
--     skybox = "github.com/Nanskip/cubzh-modules/skybox"
-- }
--------------------------------------------------------------
-- 2. Make your config, here's the example:
--------------------------------------------------------------
-- config = {
--     url = "https://e7.pngegg.com/pngimages/57/621/png-clipart-skybox-texture-mapping-panorama-others-texture-atmosphere.png",
--     scale = 1000
-- }
--------------------------------------------------------------
-- 3. Call skybox.load(config)
--
-- 4. You can also call skybox.load(config, function(obj) obj:SetParent(Camera) end)
--    to set the object as the skybox. (object is creating inside skybox.load function)

local skybox = {}

skybox.load = function(config, func)
    local defaultConfig = {
        scale = 1000,
        url = "https://e7.pngegg.com/pngimages/57/621/png-clipart-skybox-texture-mapping-panorama-others-texture-atmosphere.png"
    }

    local url = config.url or defaultConfig.url
    local scale = config.scale or defaultConfig.scale
    if func == nil then
        func = function(obj)
			obj:SetParent(Camera)
			obj.Tick = function(self)
				self.Rotation = Rotation(0, 0, 0)
				self.Position = Camera.Position - Number3(self.Scale.X, self.Scale.Y, -self.Scale.Z)/2
			end
		end
    end

	HTTP:Get(url, function(data)
		if data.StatusCode ~= 200 then
			error("Error: " .. data.StatusCode)
		end

		local image = data.Body
		local object = Object()

		object.Scale = scale

		local back = Quad()
		back.Image = image
		back.Size = Number2(1, 1)
		back.Tiling = Number2(0.25, 0.3335)
		back.Offset = Number2(0, 0.3335)
		back:SetParent(object)
		back.IsUnlit = true

		local left = Quad()
		left.Image = image
		left.Size = Number2(1, 1)
		left.Tiling = Number2(0.25, 0.3335)
		left.Offset = Number2(0.25, 0.3335)
		left.Position = back.Position + Number3(1, 0, 0)
		left.Rotation.Y = math.pi/2
		left:SetParent(object)
		left.IsUnlit = true

		local front = Quad()
		front.Image = image
		front.Size = Number2(1, 1)
		front.Tiling = Number2(0.25, 0.3335)
		front.Offset = Number2(0.5, 0.3335)
		front.Position = back.Position + Number3(1, 0, -1)
		front.Rotation.Y = math.pi
		front:SetParent(object)
		front.IsUnlit = true

		local right = Quad()
		right.Image = image
		right.Size = Number2(1, 1)
		right.Tiling = Number2(0.25, 0.3335)
		right.Offset = Number2(0.75, 0.3335)
		right.Position = back.Position + Number3(0, 0, -1)
		right.Rotation.Y = -math.pi/2
		right:SetParent(object)
		right.IsUnlit = true

		local down = Quad()
		down.Image = image
		down.Size = Number2(1, 1*1.001)
		down.Tiling = Number2(0.25, 0.3335)
		down.Offset = Number2(0.25, 0.6668)
		down.Position = back.Position + Number3(-1*0.001, 1*0.002, 0)
		down.Rotation = Rotation(math.pi/2, math.pi/2, 0)
		down:SetParent(object)
		down.IsUnlit = true

		local up = Quad()
		up.Image = image
		up.Size = Number2(1, 1)
		up.Tiling = Number2(0.25, 0.3335)
		up.Offset = Number2(0.25, 0)
		up.Position = back.Position + Number3(1, 1, 0)
		up.Rotation = Rotation(-math.pi/2, math.pi/2, 0)
		up:SetParent(object)
		up.IsUnlit = true

		func(object)
	end)
end

return skybox