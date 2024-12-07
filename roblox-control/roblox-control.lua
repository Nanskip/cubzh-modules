local module = {}

module.init = function(replace_old)
    Player.camera = Object()
    Player.forw = Object()
    Camera:SetModeFree()
    
    Player.camera.Tick = function(self, dt)
        if not module.stopped then
            local scalefactor = math.min(Player.Scale.X, math.min(Player.Scale.Y, Player.Scale.Z))+0.5
            Camera.Position = Player.Position + (Number3(0, 13, 0)*scalefactor) - Camera.Forward * 50 * scalefactor
            if Player.Motion.X ~= 0 or Player.Motion.Z ~= 0 then
                Player.Rotation:Slerp(Player.Rotation, Player.forw.Rotation, 20*dt)
            end
        end
    end

    if replace_old then
        Client.DirectionalPad = function(x, y)
            Player.camera.Forward = Camera.Forward
            Player.camera.Rotation.X = 0
        
            local cameraForward = Player.camera.Forward
            local cameraRight = Player.camera.Right
        
            Player.Motion = (cameraForward * y + cameraRight * x) * 50
            Player.forw.Forward = Number3(Player.Motion.X, 0, Player.Motion.Z)
        end
        
        Client.AnalogPad = function(dx, dy)
            Camera.Rotation = Rotation(0, dx * 0.01, 0) * Camera.Rotation
            
            Player.camera.Forward = Camera.Forward
            Player.camera.Rotation.X = 0
            
            local cameraForward = Player.camera.Forward
            local cameraRight = Player.camera.Right
        
            local dpad = require("controls").DirectionalPadValues
        
            Player.Motion = (cameraForward * dpad.Y + cameraRight * dpad.X) * 50
            Player.forw.Forward = Number3(Player.Motion.X, 0, Player.Motion.Z)
            local pitch = Camera.Rotation.X - dy * 0.01
            if pitch > 1.50 and pitch < 2 then
                pitch = 1.50
            elseif pitch > 2 and pitch < 4.8 then
                pitch = 4.8
            end
            Camera.Rotation = Rotation(pitch, Camera.Rotation.Y, Camera.Rotation.Z)
        end
        
        Pointer.Down = function(pe)
            Player.camera.lastpe = {X = pe.X, Y = pe.Y}
        end
        
        Pointer.Drag = function(pe)
            local dx = -(Player.camera.lastpe.X - pe.X)*500
            local dy = -(Player.camera.lastpe.Y - pe.Y)*500/1.2
        
            Camera.Rotation = Rotation(0, dx * 0.01, 0) * Camera.Rotation
            
            Player.camera.Forward = Camera.Forward
            Player.camera.Rotation.X = 0
            
            local cameraForward = Player.camera.Forward
            local cameraRight = Player.camera.Right
        
            local dpad = require("controls").DirectionalPadValues
        
            Player.Motion = (cameraForward * dpad.Y + cameraRight * dpad.X) * 50
            Player.forw.Forward = Number3(Player.Motion.X, 0, Player.Motion.Z)
            local pitch = Camera.Rotation.X - dy * 0.01
            if pitch > 1.50 and pitch < 2 then
                pitch = 1.50
            elseif pitch > 2 and pitch < 4.8 then
                pitch = 4.8
            end
            Camera.Rotation = Rotation(pitch, Camera.Rotation.Y, Camera.Rotation.Z)
        
            Player.camera.lastpe = {X = pe.X, Y = pe.Y}
        end
    else
        module.dirpad = LocalEvent:Listen(LocalEvent.Name.DirPad, function(x, y)
            Player.camera.Forward = Camera.Forward
            Player.camera.Rotation.X = 0
        
            local cameraForward = Player.camera.Forward
            local cameraRight = Player.camera.Right
        
            Player.Motion = (cameraForward * y + cameraRight * x) * 50
            Player.forw.Forward = Number3(Player.Motion.X, 0, Player.Motion.Z)
        end)
        
        module.analogpad = LocalEvent:Listen(LocalEvent.Name.AnalogPad, function(dx, dy)
            Camera.Rotation = Rotation(0, dx * 0.01, 0) * Camera.Rotation
            
            Player.camera.Forward = Camera.Forward
            Player.camera.Rotation.X = 0
            
            local cameraForward = Player.camera.Forward
            local cameraRight = Player.camera.Right
        
            local dpad = require("controls").DirectionalPadValues
        
            Player.Motion = (cameraForward * dpad.Y + cameraRight * dpad.X) * 50
            Player.forw.Forward = Number3(Player.Motion.X, 0, Player.Motion.Z)
            local pitch = Camera.Rotation.X - dy * 0.01
            if pitch > 1.50 and pitch < 2 then
                pitch = 1.50
            elseif pitch > 2 and pitch < 4.8 then
                pitch = 4.8
            end
            Camera.Rotation = Rotation(pitch, Camera.Rotation.Y, Camera.Rotation.Z)
        end)
        
        module.down = LocalEvent:Listen(LocalEvent.Name.PointerDown, function(pe)
            Player.camera.lastpe = {X = pe.X, Y = pe.Y}
        end)
        
        module.drag = LocalEvent:Listen(LocalEvent.Name.PointerDrag, function(pe)
            local dx = -(Player.camera.lastpe.X - pe.X)*500
            local dy = -(Player.camera.lastpe.Y - pe.Y)*500/1.2
        
            Camera.Rotation = Rotation(0, dx * 0.01, 0) * Camera.Rotation
            
            Player.camera.Forward = Camera.Forward
            Player.camera.Rotation.X = 0
            
            local cameraForward = Player.camera.Forward
            local cameraRight = Player.camera.Right
        
            local dpad = require("controls").DirectionalPadValues
        
            Player.Motion = (cameraForward * dpad.Y + cameraRight * dpad.X) * 50
            Player.forw.Forward = Number3(Player.Motion.X, 0, Player.Motion.Z)
            local pitch = Camera.Rotation.X - dy * 0.01
            if pitch > 1.50 and pitch < 2 then
                pitch = 1.50
            elseif pitch > 2 and pitch < 4.8 then
                pitch = 4.8
            end
            Camera.Rotation = Rotation(pitch, Camera.Rotation.Y, Camera.Rotation.Z)
        
            Player.camera.lastpe = {X = pe.X, Y = pe.Y}
        end)
    end
end

module.pause = function()
    module.stopped = true
    if module.dirpad ~= nil then
        module.dirpad:Pause()
        module.analogpad:Pause()
        module.down:Pause()
        module.drag:Pause()
    end
end

module.resume = function()
    module.stopped = false
    if module.dirpad ~= nil then
        module.dirpad:Resume()
        module.analogpad:Resume()
        module.down:Resume()
        module.drag:Resume()
    end
end

return module