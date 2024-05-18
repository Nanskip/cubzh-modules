
---.____________________________________________________________________________.---
---[                                                                            ]---
---[                         JOYSTICKS MODULE FOR CUBZH                         ]---
---[                              MADE BY NANSKIP                               ]---
---[                                FREE TO USE                                 ]---
---[____________________________________________________________________________]---
------------------------------------------------------------------------------------

joysticks = {}

joysticks.create = function(config)
    local defaultConfig = {
        pos = {0, 0},
        color = Color(255, 255, 255, 127),
        borderColor = Color(255, 255, 255),
        scale = 1
    }

    local ui = require("uikit")

    if config == nil then
        config = {}
    end

    for key, value in pairs(defaultConfig) do
        if config[key] == nil then
            config[key] = defaultConfig[key]
        end
    end

    local joystick = Object()
    joystick.config = config

    Object:Load("nanskip.joystick", function(item)
        if joystick ~= nil then
            joystick.shape = ui:createShape(item)
            joystick.shape.shape.Palette[1].Color = joystick.config.borderColor
            joystick.shape.shape.Palette[2].Color = joystick.config.color

            joystick.shape.Width = 160*joystick.config.scale
            joystick.shape.Height = 160*joystick.config.scale
            joystick.shape.pos.X = joystick.config.pos[1]
            joystick.shape.pos.Y = joystick.config.pos[2]
        end 
    end)

    Object:Load("nanskip.joystick_stick", function(item)
        if joystick ~= nil then
            joystick.stick = ui:createShape(item)
            joystick.stick.shape.Palette[1].Color = joystick.config.borderColor
            joystick.stick.shape.Palette[2].Color = joystick.config.color

            joystick.stick.Width = 64*joystick.config.scale
            joystick.stick.Height = 64*joystick.config.scale
            joystick.stick.pos.X = joystick.config.pos[1] + 48 * joystick.config.scale
            joystick.stick.pos.Y = joystick.config.pos[2] + 48 * joystick.config.scale
        end
    end)

    joystick.onPress = function()
        return
    end

    joystick.onRelease = function()
        return
    end

    joystick.onDrag = function()
        return
    end

    joystick.getValues = function(self)
        if self == nil then
            error("joystick.getValues() must be called with ':'!", 3)

            return
        end

        if self.x == nil then self.x = 0 end
        if self.y == nil then self.y = 0 end
        
        return Number2(self.x, self.y)
    end

    joystick.remove = function(self)
        if self == nil then
            error("joystick.remove() must be called with ':'!", 3)

            return
        end

        if self.shape ~= nil then 
            self.shape:setParent(nil)
            self.shape = nil
        end
        if self.stick ~= nil then 
            self.stick:setParent(nil)
            self.stick = nil
        end
        
        self.drag:Remove()
        self.drag = nil
        self.down:Remove()
        self.down = nil
        self.up:Remove()
        self.up = nil
        self.gotDown = nil
        self.gotUp = nil
        self.gotDrag = nil
        self:SetParent(nil)
        self = nil
    end

    joystick.gotUp = function(self, payload)
        if self == nil then
            error("joystick.gotDown() should be called with ':'!", 3)

            return
        end

        local index = payload.Index

        local posX = payload.X * Screen.Width
        local posY = payload.Y * Screen.Height
        local centerX = ((320*self.config.scale)/4)+self.shape.pos.X - (32*self.config.scale)
        local centerY = ((320*self.config.scale)/4)+self.shape.pos.Y - (32*self.config.scale)

        
        if self.dist(Number2(posX, posY), self.stick.fakepos) < 4  and payload.Index == self.index then
            self.dragging = false
            
            self.x = 0
            self.y = 0

            self.stick.pos = Number2(centerX, centerY)

            if self.onRelease ~= nil and type(self.onRelease) == "function" then
                self.onRelease()
            end
        end
    end

    joystick.gotDown = function(self, payload)
        if self == nil then
            error("joystick.gotUp() should be called with ':'!", 3)

            return
        end

        local index = payload.Index
        
        local posX = payload.X * Screen.Width
        local posY = payload.Y * Screen.Height
        local centerX = ((320*self.config.scale)/4)+self.shape.pos.X
        local centerY = ((320*self.config.scale)/4)+self.shape.pos.Y

        self.stick.fakepos = Number2(posX, posY)

        if self.dist(Number2(posX, posY), Number2(centerX, centerY)) < 80*self.config.scale then
            self.dragging = true
            self.index = index

            self:gotDrag(payload)

            if self.onPress ~= nil and type(self.onPress) == "function" then
                self.onPress()
            end
        end
    end

    joystick.gotDrag = function(self, payload)
        if self == nil then
            error("joystick.gotDrag() should be called with ':'!", 3)
            return
        end

        local index = payload.Index

        if self.dragging and payload.Index == self.index then
            local posX = payload.X * Screen.Width
            local posY = payload.Y * Screen.Height
            local centerX = ((192*self.config.scale)/4)+self.shape.pos.X
            local centerY = ((192*self.config.scale)/4)+self.shape.pos.Y
            local radius = 80*self.config.scale
        
            local offsetX = posX - centerX - (32*self.config.scale)
            local offsetY = posY - centerY - (32*self.config.scale)
        
            local distance = math.sqrt(offsetX * offsetX + offsetY * offsetY)
            self.stick.fakepos = Number2(posX, posY)
        
            if distance > radius then
                local scale = radius / distance
                offsetX = offsetX * scale
                offsetY = offsetY * scale
            end

            self.x = ((offsetX + (32*self.config.scale))/(160*self.config.scale)-0.2)*2
            self.y = ((offsetY + (32*self.config.scale))/(160*self.config.scale)-0.2)*2

            self.stick.pos = Number2(centerX + offsetX, centerY + offsetY)

            if self.onDrag ~= nil and type(self.onDrag) == "function" then
                self.onDrag()
            end
        end
    end

    joystick.drag = LocalEvent:Listen(LocalEvent.Name.PointerDrag, function(payload)
        joystick:gotDrag(payload)
    end)

    joystick.down = LocalEvent:Listen(LocalEvent.Name.PointerDown, function(payload)
        joystick:gotDown(payload)
    end)
    
    joystick.up = LocalEvent:Listen(LocalEvent.Name.PointerUp, function(payload)
        joystick:gotUp(payload)
    end)

    joystick.dist = function(pos1, pos2)
        return math.sqrt((pos1.X-pos2.X)*(pos1.X-pos2.X) + (pos1.Y-pos2.Y)*(pos1.Y-pos2.Y))
    end

    return joystick
end

return joysticks