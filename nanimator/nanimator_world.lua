Config = {
    Map = "aduermael.hills",
	Items = {
        "nanskip.v"
    }
}

Client.OnStart = function()
    ui = require("uikit")
    gallery = require("gallery") 
    aGizmo = require("gizmo")
    hierarchyActions = require("hierarchyactions")

    Camera:SetModeFree()
    Camera.FOV = 60
    globalDx = 0 globalDy = 0
    scrollNumber = 1
    playing = false
    playSpeed = 12
    --Player:SetParent(nil)

    startPos = Number3(Map.Width*Map.Scale.X/2, Map.Height*Map.Scale.Y/1.2, Map.Depth*Map.Scale.Z/2)
    Camera.Position = startPos

    createUI()
    createLocalEvents()
    createLerps()
    aGizmo:setLayer(2)
    gizmo = aGizmo:create({
		orientation = 1,
		moveSnap = 0.5,
	})
    gizmo:setMode(aGizmo.Mode.Rotate)
    gizmo:setOnRotateEnd(function()
        gizmo:setObject(nil)
        gizmo:setObject(selectedObject)

        gizmo:getObject():addKeyframe((timeline.selectedTime+timeline.frameOffset)//timeline.stepSize)
    end)
    gizmo:setOnMoveEnd(function()
        gizmo:getObject():addKeyframe((timeline.selectedTime+timeline.frameOffset)//timeline.stepSize)
    end)
    Camera.Layers = {1, 2}
end

Client.Tick = function(dt)
    Camera.Rotation.Z = 0

    Camera.Position = Camera.Position + Camera.Forward*globalDy + Camera.Right*globalDx
    if shiftPressed then Camera.Position = Camera.Position + Number3(0, -1, 0) end
    if spacePressed then Camera.Position = Camera.Position + Number3(0, 1, 0) end

    timeline.updated = false

    if playing then
        local delta = dt*62.5
        local frame = (delta*playSpeed)/62.5
        timeline.indexTime = timeline.indexTime + frame

        timeline.updateObjects()
        timeline.cursorLine.pos.X = ((timeline.indexTime)*timeline.stepSize + 270 ) - timeline.frameOffset
        timeline.cursor.pos.X = (timeline.indexTime)*timeline.stepSize + 267 - timeline.frameOffset

        timeline.updateTime()
        if timeline.cursorLine.pos.X > timeline.background.Width-70 then
            timeline.frameOffset = timeline.frameOffset + timeline.stepSize*10
            timeline.update()
        end
        if timeline.indexTime > timeline.maxTime then
            timeline.indexTime = timeline.savedindexTime
            timeline.updateObjects()
            playing = false
            timeline.playButton.Text = "▶️"
            timeline.cursorLine.pos.X = ((timeline.indexTime)*timeline.stepSize + 270 ) - timeline.frameOffset
            timeline.cursor.pos.X = (timeline.indexTime)*timeline.stepSize + 267 - timeline.frameOffset
        end
    end
end

Pointer.Down = function( pointerEvent )
    local impact = pointerEvent:CastRay()
    if impact.Object == nil then
        gizmo:setObject(nil)
        return
    elseif impact.Object == Map then
        gizmo:setObject(nil)
        return
    elseif type(impact.Object) ~= "Shape" then
        return
    else
        selectedObject = impact.Object
        gizmo:setObject(selectedObject)
    end
end

Pointer.Drag2 = function(pointerEvent)
    Camera.Rotation = Camera.Rotation + Rotation(-pointerEvent.DY*0.003, pointerEvent.DX*0.003, 0)
end

Client.DirectionalPad = function(dx, dy)
    globalDx = dx
    globalDy = dy
end

createLocalEvents = function()
    keyboardListener = LocalEvent:Listen(LocalEvent.Name.KeyboardInput, function(self, char, keyCode, down)
        if char == 0 and keyCode == 4 then
            if down then
                shiftPressed = true
            else
                shiftPressed = false
            end
        end
        if char == 117 and keyCode == 0 then
            if down then
                spacePressed = true
            else
                spacePressed = false
            end
        end
    end)
end

createUI = function()
    buttons = {}

    buttons.loadModel = ui:createButton("Load Model")
    buttons.loadModel.size = Number2(buttons.loadModel.size.X, buttons.loadModel.size.Y + 8)
    buttons.loadModel.pos = Number2(Screen.Width - buttons.loadModel.size.X - 8 - Screen.SafeArea.Right, Screen.Height - buttons.loadModel.size.Y - 8 - Screen.SafeArea.Top)
    -- stolen from S&Cubzh 2 by fab3kleuuu
    buttons.loadModel.onPress = function()
        local function maxModalWidth()
            local computed = Screen.Width - Screen.SafeArea.Left - Screen.SafeArea.Right - 50
            local max = 1400
            local w = math.min(max, computed)
            return w
        end

        local function maxModalHeight()
            local vMargin = 20
            local h = Screen.Height - Screen.SafeArea.Top - Screen.SafeArea.Bottom - vMargin
            return h
        end

        local function updateModalPosition(modal, forceBounce)
            local vCenter = Screen.Height * 0.5
            local p = Number3(Screen.Width * 0.5 - modal.Width * 0.5, vCenter - modal.Height * 0.5, 0)

            modal.LocalPosition = p
        end

        local items_gallery = gallery:create(maxModalWidth, maxModalHeight, updateModalPosition)
        local grid = items_gallery.contentStack[1].node
        grid.onOpen = function(self, cell)
            Object:Load(cell.itemFullName, function(self)
                if model ~= nil then
                    model:SetParent(nil)
                end
                model = self
                model:SetParent(World)
                loadModel(model)
            end)
            items_gallery:close()
        end
    end
    -- end of stolen part :3

    timeline = Object()

    timeline.selectedTime = 0
    timeline.maxTime = 0
    timeline.indexTime = 0
    timeline.stepSize = 20
    timeline.frameOffset = 0
    timeline.animations = {}
    timeline.keyframes = {}

    timeline.background = ui:createFrame(Color(0, 0, 0, 0.5))
    timeline.background.size = Number2(Screen.Width - 40 - 200, 210)
    timeline.background.pos = Number2(10, 10)
    timeline.background.onPress = function() return end

    timeline.updateTime = function()
        timeline.time.Text = "Time: " .. string.format("%.0f", timeline.indexTime) .. "/" .. timeline.maxTime
    end

    timeline.background.onDrag = function(self, pe)
        local x = math.floor(pe.X * Screen.Width)
        local y = math.floor(pe.Y * Screen.Width)

        timeline.selectedTime = math.min(math.max(0, (x)-270), timeline.background.Width-295) // timeline.stepSize * timeline.stepSize
        timeline.indexTime = timeline.selectedTime // timeline.stepSize
        timeline.cursorLine.pos.X = timeline.selectedTime + 270
        timeline.cursor.pos.X = timeline.selectedTime + 267
        if not timeline.updated then
            timeline.updateObjects()
            timeline.updateTime()
        end
        timeline.updated = true
    end

    timeline.background2 = ui:createFrame(Color(0, 0, 0, 0.3))
    timeline.background2.size = Number2(255, 210)
    timeline.background2.pos = Number2(10, 10)
    timeline.background2.onPress = function() return end

    timeline.background3 = ui:createFrame(Color(0.2, 0.2, 0.2, 0.5))
    timeline.background3.size = Number2(220, 210)
    timeline.background3.pos = Number2(10+timeline.background.Width, 10)
    timeline.background3.onPress = function() return end

    timeline.backgroundVertLine1 = ui:createFrame(Color(0, 0, 0, 0.2))
    timeline.backgroundVertLine1.size = Number2(5, timeline.background.size.Y)
    timeline.backgroundVertLine1.pos = Number2(265, 10)
    timeline.backgroundVertLine2 = ui:createFrame(Color(0, 0, 0, 0.2))
    timeline.backgroundVertLine2.size = Number2(5, timeline.background.size.Y)
    timeline.backgroundVertLine2.pos = Number2(10, 10)
    timeline.backgroundVertLine3 = ui:createFrame(Color(0, 0, 0, 0.2))
    timeline.backgroundVertLine3.size = Number2(5, timeline.background.size.Y)
    timeline.backgroundVertLine3.pos = Number2(5+timeline.background.Width +timeline.background3.Width, 10)
    timeline.backgroundVertLine4 = ui:createFrame(Color(0, 0, 0, 0.2))
    timeline.backgroundVertLine4.size = Number2(5, timeline.background.size.Y)
    timeline.backgroundVertLine4.pos = Number2(10+timeline.background.Width, 10)

    timeline.backgroundHoriLine1 = ui:createFrame(Color(0, 0, 0, 0.2))
    timeline.backgroundHoriLine1.size = Number2(210, 5)
    timeline.backgroundHoriLine1.pos = Number2(15+timeline.background.Width, 10)
    timeline.backgroundHoriLine2 = ui:createFrame(Color(0, 0, 0, 0.2))
    timeline.backgroundHoriLine2.size = Number2(210, 5)
    timeline.backgroundHoriLine2.pos = Number2(15+timeline.background.Width, timeline.background.size.Y+5)

    timeline.time = ui:createText("Time: " .. timeline.selectedTime .. "/" .. timeline.maxTime, Color(255, 255, 255))
    timeline.time.pos = Number2(Screen.Width - 200-20, 230-38-3)

    timeline.shapes = {}
    timeline.buttons = {}

    timeline.upButton = ui:createButton("⬆", {borders = false, shadow = false})
    timeline.upButton.pos = Number2(Screen.Width - 200-30-36, 10+210-36)
    timeline.upButton.onRelease = function()
        if scrollNumber > 1 then
            scrollNumber = scrollNumber - 1
        end
        timeline.update()
    end

    timeline.downButton = ui:createButton("⬇", {borders = false, shadow = false})
    timeline.downButton.pos = Number2(Screen.Width - 200-30-36, 10)
    timeline.downButton.onRelease = function()
        if scrollNumber < #timeline.shapes-4 then
            scrollNumber = scrollNumber + 1
        end
        timeline.update()
    end

    timeline.rotateButton = ui:createButton("↻", {borders = false, shadow = false})
    timeline.rotateButton.pos = Number2(Screen.Width - 220, 20)
    timeline.rotateButton.onRelease = function()
        gizmo:setMode(aGizmo.Mode.Rotate)
    end

    timeline.moveButton = ui:createButton("⇢", {borders = false, shadow = false})
    timeline.moveButton.pos = Number2(Screen.Width - 220 + 36, 20)
    timeline.moveButton.onRelease = function()
        gizmo:setMode(aGizmo.Mode.Move)
    end

    timeline.localButton = ui:createButton("🏠", {borders = false, shadow = false})
    timeline.localButton.pos = Number2(Screen.Width - 220 + 36*2 + 5, 20)
    timeline.localButton.onRelease = function()
        gizmo:setOrientation(aGizmo.Orientation.Local)
    end

    timeline.globalButton = ui:createButton("🌎", {borders = false, shadow = false})
    timeline.globalButton.pos = Number2(Screen.Width - 220 + 36*3 + 5, 20)
    timeline.globalButton.onRelease = function()
        gizmo:setOrientation(aGizmo.Orientation.World)
    end

    timeline.resetButton = ui:createButton("🔁", {borders = false, shadow = false})
    timeline.resetButton.pos = Number2(Screen.Width - 20-36, 20)
    timeline.resetButton.onRelease = function()
        selectedObject.LocalRotation = selectedObject.defaultRotation
        selectedObject.LocalPosition = selectedObject.defaultPosition
    end

    timeline.addKeyframeButton = ui:createButton("➕", {borders = false, shadow = false})
    timeline.addKeyframeButton.pos = Number2(Screen.Width - 200-30-36, 10+210)
    timeline.addKeyframeButton.onRelease = function()
        if gizmo:getObject() ~= nil then
            gizmo:getObject():addKeyframe((timeline.selectedTime+timeline.frameOffset)//timeline.stepSize)
        end
    end

    timeline.removeKeyframeButton = ui:createButton("➖", {borders = false, shadow = false})
    timeline.removeKeyframeButton.pos = Number2(Screen.Width - 200-30-36*2, 10+210)
    timeline.removeKeyframeButton.onRelease = function()
        if gizmo:getObject() ~= nil then
            gizmo:getObject():removeKeyframe((timeline.selectedTime+timeline.frameOffset)//timeline.stepSize)
        end
    end

    timeline.leftFrameButton = ui:createButton("⬆", {borders = false, shadow = false})
    timeline.leftFrameButton.pos = Number2(Screen.Width - 200-30-36*3, 10+210)
    timeline.leftFrameButton.Rotation.Z = math.pi/2
    timeline.leftFrameButton.onRelease = function()
        timeline.frameOffset = timeline.frameOffset - timeline.stepSize*10
        timeline.update()
    end

    timeline.rightFrameButton = ui:createButton("⬇", {borders = false, shadow = false})
    timeline.rightFrameButton.pos = Number2(Screen.Width - 200-30-36*2, 10+210)
    timeline.rightFrameButton.Rotation.Z = math.pi/2
    timeline.rightFrameButton.onRelease = function()
        timeline.frameOffset = timeline.frameOffset + timeline.stepSize*10
        timeline.update()
    end

    timeline.playButton = ui:createButton("▶️", {borders = false, shadow = false})
    timeline.playButton.pos = Number2(Screen.Width - 220, 20+38+5)
    timeline.playButton.onRelease = function()
        if not playing then
            timeline.savedindexTime = timeline.indexTime
            playing = true
            timeline.playButton.Text = "⏹️"
        else
            timeline.indexTime = timeline.savedindexTime
            timeline.cursorLine.pos.X = ((timeline.indexTime)*timeline.stepSize + 270 ) - timeline.frameOffset
            timeline.cursor.pos.X = (timeline.indexTime)*timeline.stepSize + 267 - timeline.frameOffset
            playing = false
            timeline.updateObjects()
            timeline.playButton.Text = "▶️"
        end
    end

    timeline.speedEdit = ui:createTextInput(tostring(playSpeed), "Speed")
    timeline.speedEdit.pos = Number2(Screen.Width - 220 + 38 + 5, 20+38+5)
    timeline.speedEdit.Width = 156/2
    timeline.speedEdit.onTextChange = function()
        playSpeed = tonumber(timeline.speedEdit.Text) or 1
        if playSpeed < 1 then
            playSpeed = 1
        end
        if playSpeed > 6000 then
            playSpeed = 6000
        end
    end

    timeline.buttonsBackground = ui:createFrame(Color(0, 0, 0, 0.4))
    timeline.buttonsBackground.size = Number2(38, 210-(37*2))
    timeline.buttonsBackground.pos = Number2(Screen.Width - 200-30-36, 48)

    timeline.horizontalLines = {}

    for i=1, 6 do
        timeline.horizontalLines[i] = ui:createFrame(Color(0, 0, 0, 0.2))
        timeline.horizontalLines[i].size = Number2(timeline.background.Width-36, 5)
        timeline.horizontalLines[i].pos = Number2(10, 10 + (41*(i-1)))
    end

    timeline.update = function()
        if timeline.frameOffset < 0 then
            timeline.frameOffset = 0
        end
        for k, v in ipairs(timeline.buttons) do
            timeline.buttons[k].pos = Number2(-1000, -1000)
            timeline.buttons[k].line.pos = Number2(-1000, -1000)
            timeline.buttons[k].line2.pos = Number2(-1000, -1000)
            if timeline.buttons[k].line3 ~= nil then
                timeline.buttons[k].line3.pos = Number2(-1000, -1000)
            end
        end

        for k, v in pairs(timeline.keyframes) do
            for key, value in pairs(timeline.keyframes[k]) do
                timeline.keyframes[k][key]:remove()
                timeline.keyframes[k][key] = nil
            end
        end

        for i = scrollNumber, scrollNumber + 4 do
            if timeline.shapes[i] == nil then break end

            local v = timeline.shapes[i]
            timeline.buttons[i].pos = Number2(15, 179 - ((36 + 5))*(i-scrollNumber))
            timeline.buttons[i].Width = 250

            timeline.buttons[i].pos.X = timeline.buttons[i].pos.X + 10*v.depth
            timeline.buttons[i].Width = timeline.buttons[i].Width - 10*v.depth
            timeline.buttons[i].line.size = Number2(math.min(10*v.depth, 10), 5)
            timeline.buttons[i].line.pos = Number2(timeline.buttons[i].pos.X - 10, timeline.buttons[i].pos.Y + 20-3)
            timeline.buttons[i].line2.size = Number2(5, 14)
            timeline.buttons[i].line2.pos = Number2(timeline.buttons[i].pos.X - 10, timeline.buttons[i].pos.Y + 22)
            if timeline.buttons[i].line3 ~= nil then
                timeline.buttons[i].line3.size = Number2(5, 17)
                timeline.buttons[i].line3.pos = Number2(timeline.buttons[i].pos.X - 10, timeline.buttons[i].pos.Y)
            end

            for k, v in pairs(timeline.animations[selectedAnimation].shapes[v.name].frames) do
                if timeline.keyframes[v] == nil then timeline.keyframes[v] = {} end
                timeline.keyframes[v][k] = ui:createFrame(Color(0, 255, 255))
                timeline.keyframes[v][k].size = Number2(14, 14.5)
                timeline.keyframes[v][k].pos = Number2(273 + (k)*timeline.stepSize-timeline.frameOffset, timeline.buttons[i].pos.Y + 8)
                timeline.keyframes[v][k].Rotation.Z = math.pi/4
                if timeline.keyframes[v][k].pos.X < 273 or timeline.keyframes[v][k].pos.X > Screen.Width-266 then
                    timeline.keyframes[v][k]:remove()
                    timeline.keyframes[v][k] = nil
                end
            end
        end
    end

    timeline.updateObjects = function()
        hierarchyActions:applyToDescendants(model,  { includeRoot = true }, function(s)
            local left_keyframe = 0
            local right_keyframe = 0

            local keyframes = {}
            for _, text in pairs(timeline.animations[selectedAnimation].shapes[s.name].frames) do
                table.insert(keyframes, tonumber(_))
                if tonumber(_) > right_keyframe then
                    right_keyframe = tonumber(_)
                end
            end
            local invertedKeyframes = {}
            for i=#keyframes, 1, -1 do
                invertedKeyframes[i] = keyframes[i]
            end

            if #keyframes < 2 then
                return
            end

            if timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(timeline.indexTime)] ~= nil then
                left_keyframe = timeline.indexTime
                right_keyframe = timeline.indexTime
            else
                for _, keyframe in ipairs(keyframes) do
                    if keyframe < timeline.indexTime and keyframe > left_keyframe then
                        left_keyframe = keyframe
                    end
                end
    
                for _, keyframe in ipairs(invertedKeyframes) do
                    if keyframe > timeline.indexTime and keyframe < right_keyframe  then
                        right_keyframe = keyframe
                    end
                end
            end

            local time = 0
            if left_keyframe ~= nil and right_keyframe ~= nil and right_keyframe ~= left_keyframe then
                time = (timeline.indexTime - left_keyframe) / (right_keyframe - left_keyframe)
            end

            if timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(left_keyframe)].rotation ~= nil and timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(right_keyframe)].rotation ~= nil then
                s.LocalRotation:Slerp(
                    timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(left_keyframe)].rotation,
                    timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(right_keyframe)].rotation,
                    lerp[timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(right_keyframe)].interpolation](time)
                )
                s.LocalPosition:Lerp(
                    timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(left_keyframe)].position,
                    timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(right_keyframe)].position,
                    lerp[timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(right_keyframe)].interpolation](time)
                )
            end
        end)
    end

    timeline.cursor = ui:createFrame(Color(255, 255, 0))
    timeline.cursor.size = Number2(11, 12)
    timeline.cursor.pos = Number2(265, 215)

    timeline.cursorLine = ui:createFrame(Color(255, 255, 255, 0.6))
    timeline.cursorLine.size = Number2(5, 200)
    timeline.cursorLine.pos = Number2(268, 15)

    animationSelector = Object()
    animationSelector = ui:createFrame(Color(0, 0, 0, 0.5))
    animationSelector.size = Number2(260, 320)
    animationSelector.pos = Number2(10, 230)
    animationSelector.onPress = function() return end
end

loadModel = function(model)
    if model == nil then
        return
    end

    scrollNumber = 1

    for k, v in ipairs(timeline.shapes) do
        timeline.shapes[k]:SetParent(nil)
        timeline.shapes[k] = nil
    end

    for k, v in pairs(timeline.keyframes) do
        for key, value in pairs(timeline.keyframes[k]) do
            timeline.keyframes[k][key]:remove()
            timeline.keyframes[k][key] = nil
        end
    end

    for k, v in ipairs(timeline.buttons) do
        timeline.buttons[k].line:remove()
        timeline.buttons[k].line = nil
        timeline.buttons[k].line2:remove()
        timeline.buttons[k].line2 = nil

        if timeline.buttons[k].line3 ~= nil then
            timeline.buttons[k].line3:remove()
            timeline.buttons[k].line3 = nil
        end

        timeline.buttons[k]:remove()
        timeline.buttons[k] = nil
    end

    for k, v in ipairs(timeline.animations) do
        timeline.animations[k]:remove()
        timeline.animations[k] = nil
    end

    selectedAnimation = "default"

    timeline.animations["default"] = {
        shapes = {}
    }

    model.Position = startPos

    hierarchyActions:applyToDescendants(model,  { includeRoot = true }, function(s)
        table.insert(timeline.shapes, s)
        
        local parent = s:GetParent()
        if parent.depth == nil then parent.depth = -1 end
        s.depth = parent.depth + 1
        s.Physics = PhysicsMode.StaticPerBlock

        s.defaultPosition = Number3(s.LocalPosition.X, s.LocalPosition.Y, s.LocalPosition.Z)
        s.defaultRotation = Rotation(s.LocalRotation.X, s.LocalRotation.Y, s.LocalRotation.Z)

        s.addKeyframe = function(self, time)
            if timeline.animations[selectedAnimation].shapes[self.name].frames[tostring(time)] == nil then
                timeline.animations[selectedAnimation].shapes[self.name].frames[tostring(time)] = {
                    position = Number3(s.LocalPosition.X, s.LocalPosition.Y, s.LocalPosition.Z),
                    rotation = Rotation(s.LocalRotation.X, s.LocalRotation.Y, s.LocalRotation.Z),
                    interpolation = "linear"
                }
                checkforKeyframe(time)
            else
                self:removeKeyframe(time)
                timeline.animations[selectedAnimation].shapes[self.name].frames[tostring(time)] = {
                    position = Number3(s.LocalPosition.X, s.LocalPosition.Y, s.LocalPosition.Z),
                    rotation = Rotation(s.LocalRotation.X, s.LocalRotation.Y, s.LocalRotation.Z),
                    interpolation = "linear"
                }
                checkforKeyframe(time)
            end

            timeline.update()
        end

        s.removeKeyframe = function(self, time)
            timeline.animations[selectedAnimation].shapes[self.name].frames[tostring(time)] = nil

            timeline.update()
        end
    end)

    for k, v in ipairs(timeline.shapes) do
        local name = v.Name
        if name == nil or name == "(null)" then name = "shape_" .. math.random(1000, 9999) end
        v.name = name .. #timeline.buttons
        timeline.buttons[k] = ui:createButton(name .. " [#" .. #timeline.buttons .. "]", {borders = false, color = Color(0.2, 0.2, 0.2, 0.3), colorPressed = Color(0.3, 0.3, 0.3, 0.3), shadow = false})
        timeline.buttons[k].pos = Number2(15, 15 + ((timeline.buttons[k].Height + 5))*(k-1))

        if v.depth == nil then v.depth = 0 end
        timeline.buttons[k].Width = 250

        timeline.buttons[k].pos.X = timeline.buttons[k].pos.X + 10*v.depth
        timeline.buttons[k].Width = timeline.buttons[k].Width - 10*v.depth
        timeline.buttons[k].Height = 36
        timeline.buttons[k].line = ui:createFrame(Color(255, 255, 255, 0.2))
        timeline.buttons[k].line.size = Number2(math.min(10*v.depth, 10), 5)
        timeline.buttons[k].line.pos = Number2(timeline.buttons[k].pos.X - 10, timeline.buttons[k].pos.Y + 20-3)

        timeline.buttons[k].line2 = ui:createFrame(Color(255, 255, 255, 0.2))
        timeline.buttons[k].line2.size = Number2(5, 14)
        timeline.buttons[k].line2.pos = Number2(timeline.buttons[k].pos.X - 10, timeline.buttons[k].pos.Y + 22)

        local parent = v:GetParent()

        for i = 1, parent.ChildrenCount do
            local child = parent:GetChild(i)

            if child == v and i < parent.ChildrenCount then
                timeline.buttons[k].line3 = ui:createFrame(Color(255, 255, 255, 0.2))
                timeline.buttons[k].line3.size = Number2(5, 17)
                timeline.buttons[k].line3.pos = Number2(timeline.buttons[k].pos.X - 10, timeline.buttons[k].pos.Y)
            end
        end
        
        timeline.buttons[k].onRelease = function()
            selectedObject = v
            gizmo:setObject(v)
        end

        timeline.animations[selectedAnimation].shapes[v.name] = {name = v.name}
        timeline.animations[selectedAnimation].shapes[v.name].frames = {}
    end

    timeline.update()
end

createLerps = function()
    lerp = {}

    lerp.linear = function(t) return t end
    lerp.quadraticIn = function(t) return t*t end
    lerp.cubicIn = function(t) return t*t*t end
    lerp.quadraticOut = function(t) return t*(2-t) end
    lerp.cubicOut = function(t) return t*(2-t)*(2-t) end

    lerp.interpolate = function(a, b, t, type)
        t = lerp[type](t)

        return a*(1-t) + b*t
    end
end

checkforKeyframe = function(time)
    if timeline.maxTime < time then timeline.maxTime = time end
end