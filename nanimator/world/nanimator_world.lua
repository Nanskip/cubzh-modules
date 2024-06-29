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
    avatar = require("avatar")

    Camera:SetModeFree()
    Camera.FOV = 60
    globalDx = 0 globalDy = 0
    scrollNumber = 1
    playing = false
    playSpeed = 12
    selectedInterp = "linear"
    loadedModelName = ""
    --Player:SetParent(nil)

    startPos = Number3(Map.Width*Map.Scale.X/2, Map.Height*Map.Scale.Y/1.2, Map.Depth*Map.Scale.Z/2)
    Map.Position = Map.Position - startPos

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

        gizmo:getObject():addKeyframe((timeline.selectedTime+timeline.frameOffset)//timeline.stepSize, selectedInterp)
    end)
    gizmo:setOnMoveEnd(function()
        gizmo:getObject():addKeyframe((timeline.selectedTime+timeline.frameOffset)//timeline.stepSize, selectedInterp)
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
            timeline.offsetTime = timeline.savedoffsetTime 
            timeline.updateObjects()
            timeline.update()
            playing = false
            timeline.playButton.Text = "▶️"
            timeline.cursorLine.pos.X = ((timeline.indexTime)*timeline.stepSize + 270 ) - timeline.frameOffset
            timeline.cursor.pos.X = (timeline.indexTime)*timeline.stepSize + 267 - timeline.frameOffset
        end
    end

    if buttons.exportText ~= nil then
        if buttons.exportTextTimer > 1 then
            if buttons.exportTextTimer < 255 then
                buttons.exportText:_setColor(Color(0, 0, 0, buttons.exportTextTimer//4))
                buttons.exportText2:_setColor(Color(255, 255, 255, buttons.exportTextTimer))
            else
                buttons.exportText:_setColor(Color(0, 0, 0, 255//4))
                buttons.exportText2:_setColor(Color(255, 255, 255, 255))
            end
            buttons.exportTextTimer = buttons.exportTextTimer - 1
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
    elseif type(impact.Object) ~= "Shape" and type(impact.Object) ~= "MutableShape" then
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
    
    buttons.hideInterface = ui:createButton("Hide Interface", {shadow = false, color = Color(0, 0, 0, 0.2), colorPressed = Color(0, 0, 0, 0.4)})
    buttons.hideInterface.Height = buttons.hideInterface.Height + 8
    buttons.hideInterface.pos = Number2(
        Screen.Width - buttons.hideInterface.size.X - 8 - Screen.SafeArea.Right, Screen.Height - buttons.hideInterface.size.Y - 8 - Screen.SafeArea.Top
    )
    buttons.hideInterface.onRelease = function()
        if timeline.IsHidden then
            timeline.IsHidden = false
            World:GetChild(2).Layers = {12}
        else
            timeline.IsHidden = true
            World:GetChild(2).Layers = {}
        end
    end

    buttons.loadModel = ui:createButton("Load Model")
    buttons.loadModel.size = Number2(156, buttons.loadModel.size.Y + 8)
    buttons.loadModel.pos = Number2(
        Screen.Width - buttons.loadModel.size.X - 8 - Screen.SafeArea.Right - buttons.hideInterface.Width - 5, Screen.Height - buttons.loadModel.size.Y - 8 - Screen.SafeArea.Top
    )

    buttons.loadModel.onRelease = function()
        buttons.loadModel:disable()

        buttons.loadShape.pos = Number2(buttons.loadModel.pos.X, buttons.loadModel.pos.Y-buttons.loadModel.size.Y-5)
        buttons.loadPlayer.pos = Number2(buttons.loadShape.pos.X, buttons.loadShape.pos.Y-buttons.loadShape.size.Y-5)
    end

    buttons.loadShape = ui:createButton("Shape model")
    buttons.loadPlayer = ui:createButton("Player model")

    buttons.loadPlayer.size = Number2(buttons.loadPlayer.size.X, buttons.loadPlayer.size.Y+8)
    buttons.loadShape.size = Number2(buttons.loadPlayer.size.X, buttons.loadPlayer.size.Y)

    buttons.loadShape.pos = Number2(-1000, -1000)
    buttons.loadPlayer.pos = Number2(-1000, -1000)

    buttons.editPlayerName = ui:createTextInput(Player.Username, "Player username")
    buttons.editPlayerName.size = Number2(220, 38)
    buttons.editPlayerName.pos = Number2(-1000, -1000)

    buttons.editPlayerNameEnter = ui:createButton("✅")
    buttons.editPlayerNameEnter.size = Number2(38, 38)
    buttons.editPlayerNameEnter.pos = Number2(-1000, -1000)

    buttons.editPlayerNameEnter.onRelease = function()
        buttons.editPlayerName.pos = Number2(-1000, -1000)
        buttons.editPlayerNameEnter.pos = Number2(-1000, -1000)

        buttons.loadModel:enable()
        buttons.loadShape.pos = Number2(-1000, -1000)
        buttons.loadPlayer.pos = Number2(-1000, -1000)
        buttons.loadPlayer:enable()
        buttons.loadShape:enable()

        loadedModelName = buttons.editPlayerName.Text
        timeline.shapeType = "player"

        if model ~= nil then
            model:SetParent(nil)
        end
    
        model = avatar:get(loadedModelName)
        model.Animations.Idle:Stop()
        model.Animations = nil
        loadModel(model)
    end

    buttons.loadPlayer.onRelease = function()
        buttons.loadPlayer:disable()
        buttons.loadShape:disable()

        buttons.editPlayerName.pos = Number2(Screen.Width/2 - buttons.editPlayerName.Width/2, Screen.Height/2 + buttons.editPlayerName.Height/2)
        buttons.editPlayerNameEnter.pos = Number2(buttons.editPlayerName.pos.X + buttons.editPlayerName.Width, buttons.editPlayerName.pos.Y)
    end

    -- stolen from S&Cubzh 2 by fab3kleuuu
    buttons.loadShape.onRelease = function()
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
            loadedModelName = cell.itemFullName
            Object:Load(loadedModelName, function(self)
                if model ~= nil then
                    model:SetParent(nil)
                end
                model = self
                loadModel(model)
                timeline.shapeType = "shape"
            end)
            items_gallery:close()
            buttons.loadModel:enable()
            buttons.loadShape.pos = Number2(-1000, -1000)
            buttons.loadPlayer.pos = Number2(-1000, -1000)
        end
    end
    -- end of stolen part :3

    buttons.import = ui:createButton("Import", {shadow = false, color = Color(8, 191, 22), colorPressed = Color(14, 153, 24)})
    buttons.import.Width = 90 buttons.import.Height = 40
    buttons.import.pos = Number2(10, Screen.Height - buttons.import.Height - 10 - Screen.SafeArea.Top)
    buttons.import.onRelease = function()
        File:OpenAndReadAll(function(success, result)
            if not success then
                print("Can't open the file.")
                return
            end

            if result == nil then
                print("File is not selected.")
                return
            end

            local str = result:ToString()
            loadedModelName = JSON:Decode(str)["shape"]
            timeline.shapeType = JSON:Decode(str)["shapeType"]

            if timeline.shapeType == "shape" then
                Object:Load(loadedModelName, function(self)
                    model = self
                    loadModel(self, true)
                    timeline.animations = JSON:Decode(str)["animations"]
                    timeline.update()
                    timeline.updateTime()
                    timeline.updateAnimations()
                    timeline.updateObjects()
                end)
            else
                model = avatar:get(loadedModelName)
                model.Animations.Idle:Stop()
                model.Animations = nil
                loadModel(model)
                timeline.animations = JSON:Decode(str)["animations"]
                timeline.update()
                timeline.updateTime()
                timeline.updateAnimations()
                timeline.updateObjects()
            end
        end)
    end
    buttons.export = ui:createButton("Export", {shadow = false, color = Color(23, 173, 173), colorPressed = Color(21, 130, 130)})
    buttons.export.Width = 90 buttons.export.Height = 40
    buttons.export.pos = Number2(10, Screen.Height - buttons.export.Height*2 - 15 - Screen.SafeArea.Top)
    buttons.export.onRelease = function()
        local save = {
            ["animations"] = timeline.animations,
            ["shape"] = loadedModelName,
            ["shapeType"] = timeline.shapeType
        }

        Dev:CopyToClipboard(JSON:Encode(save))
        buttons.exportTextTimer = 400
    end

    buttons.exportText = ui:createText("! Copied to clipboard.", Color(0, 0, 0, 0.5))
    buttons.exportText.pos = Number2(buttons.export.pos.X + buttons.export.Width + 12, buttons.export.pos.Y + 4)
    buttons.exportText2 = ui:createText("! Copied to clipboard.", Color(255, 255, 255))
    buttons.exportText2.pos = Number2(buttons.export.pos.X + buttons.export.Width + 10, buttons.export.pos.Y + 6)
    buttons.exportTextTimer = 255

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
        timeline.maxTime = timeline.animations[selectedAnimation].maxTime
        if timeline.maxTime == nil then timeline.maxTime = 0 end
        timeline.time.Text = "Time: " .. string.format("%.0f", timeline.indexTime) .. "/" .. timeline.maxTime
    end

    timeline.background.onDrag = function(self, pe)
        local x = math.floor(pe.X * Screen.Width)
        local y = math.floor(pe.Y * Screen.Width)

        timeline.selectedTime = math.min(math.max(0, (x)-270), timeline.background.Width-295) // timeline.stepSize * timeline.stepSize
        timeline.indexTime = (timeline.selectedTime+timeline.frameOffset) // timeline.stepSize
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

    timeline.upButton = ui:createButton("⬆", {borders = false, shadow = false, color = Color(46, 46, 46, 0.6), colorPressed = Color(26, 26, 26, 0.6)})
    timeline.upButton.pos = Number2(Screen.Width - 200-30-38, 10+210-38)
    timeline.upButton.onRelease = function()
        if scrollNumber > 1 then
            scrollNumber = scrollNumber - 1
        end
        timeline.update()
    end

    timeline.downButton = ui:createButton("⬇", {borders = false, shadow = false, color = Color(46, 46, 46, 0.6), colorPressed = Color(26, 26, 26, 0.6)})
    timeline.downButton.pos = Number2(Screen.Width - 200-30-38, 10)
    timeline.downButton.onRelease = function()
        if scrollNumber < #timeline.shapes-4 then
            scrollNumber = scrollNumber + 1
        end
        timeline.update()
    end

    timeline.rotateButton = ui:createButton("↻", {borders = false, shadow = false, color = Color(46, 46, 46, 0.6), colorPressed = Color(26, 26, 26, 0.6)})
    timeline.rotateButton.pos = Number2(Screen.Width - 220, 20)
    timeline.rotateButton.onRelease = function()
        gizmo:setMode(aGizmo.Mode.Rotate)
    end

    timeline.moveButton = ui:createButton("⇢", {borders = false, shadow = false, color = Color(46, 46, 46, 0.6), colorPressed = Color(26, 26, 26, 0.6)})
    timeline.moveButton.pos = Number2(Screen.Width - 220 + 38, 20)
    timeline.moveButton.onRelease = function()
        gizmo:setMode(aGizmo.Mode.Move)
    end

    timeline.localButton = ui:createButton("🏠", {borders = false, shadow = false, color = Color(46, 46, 46, 0.6), colorPressed = Color(26, 26, 26, 0.6)})
    timeline.localButton.pos = Number2(Screen.Width - 220 + 38*2 + 5, 20)
    timeline.localButton.onRelease = function()
        gizmo:setOrientation(aGizmo.Orientation.Local)
    end

    timeline.globalButton = ui:createButton("🌎", {borders = false, shadow = false, color = Color(46, 46, 46, 0.6), colorPressed = Color(26, 26, 26, 0.6)})
    timeline.globalButton.pos = Number2(Screen.Width - 220 + 38*3 + 5, 20)
    timeline.globalButton.onRelease = function()
        gizmo:setOrientation(aGizmo.Orientation.World)
    end

    timeline.resetButton = ui:createButton("🔁", {borders = false, shadow = false, color = Color(46, 46, 46, 0.6), colorPressed = Color(26, 26, 26, 0.6)})
    timeline.resetButton.pos = Number2(Screen.Width - 20-38, 20)
    timeline.resetButton.onRelease = function()
        selectedObject.LocalRotation = selectedObject.defaultRotation
        selectedObject.LocalPosition = selectedObject.defaultPosition
    end

    timeline.addKeyframeButton = ui:createButton("➕", {borders = false, shadow = false, color = Color(46, 46, 46, 0.6), colorPressed = Color(26, 26, 26, 0.6)})
    timeline.addKeyframeButton.pos = Number2(Screen.Width - 200-30-38, 10+210)
    timeline.addKeyframeButton.onRelease = function()
        if gizmo:getObject() ~= nil then
            gizmo:getObject():addKeyframe((timeline.selectedTime+timeline.frameOffset)//timeline.stepSize, selectedInterp)
        end
    end

    timeline.removeKeyframeButton = ui:createButton("➖", {borders = false, shadow = false, color = Color(46, 46, 46, 0.6), colorPressed = Color(26, 26, 26, 0.6)})
    timeline.removeKeyframeButton.pos = Number2(Screen.Width - 200-30-38*2, 10+210)
    timeline.removeKeyframeButton.onRelease = function()
        if gizmo:getObject() ~= nil then
            gizmo:getObject():removeKeyframe((timeline.selectedTime+timeline.frameOffset)//timeline.stepSize)
        end
    end

    timeline.leftFrameButton = ui:createButton("⬆", {borders = false, shadow = false, color = Color(46, 46, 46, 0.6), colorPressed = Color(26, 26, 26, 0.6)})
    timeline.leftFrameButton.pos = Number2(Screen.Width - 200-30-38*3, 10+210)
    timeline.leftFrameButton.Rotation.Z = math.pi/2
    timeline.leftFrameButton.onRelease = function()
        timeline.frameOffset = timeline.frameOffset - timeline.stepSize*10
        timeline.update()
        timeline.cursorLine.pos.X = ((timeline.indexTime)*timeline.stepSize + 270 ) - timeline.frameOffset
        timeline.cursor.pos.X = (timeline.indexTime)*timeline.stepSize + 267 - timeline.frameOffset
    end

    timeline.rightFrameButton = ui:createButton("⬇", {borders = false, shadow = false, color = Color(46, 46, 46, 0.6), colorPressed = Color(26, 26, 26, 0.6)})
    timeline.rightFrameButton.pos = Number2(Screen.Width - 200-30-38*2, 10+210)
    timeline.rightFrameButton.Rotation.Z = math.pi/2
    timeline.rightFrameButton.onRelease = function()
        timeline.frameOffset = timeline.frameOffset + timeline.stepSize*10
        timeline.update()
        timeline.cursorLine.pos.X = ((timeline.indexTime)*timeline.stepSize + 270 ) - timeline.frameOffset
        timeline.cursor.pos.X = (timeline.indexTime)*timeline.stepSize + 267 - timeline.frameOffset
    end

    timeline.playButton = ui:createButton("▶️", {borders = false, shadow = false, color = Color(46, 46, 46, 0.6), colorPressed = Color(26, 26, 26, 0.6)})
    timeline.playButton.pos = Number2(Screen.Width - 220, 20+38+5)
    timeline.playButton.onRelease = function()
        if not playing then
            timeline.savedindexTime = timeline.indexTime
            timeline.savedoffsetTime = timeline.offsetTime
            playing = true
            timeline.playButton.Text = "⏹️"
        else
            timeline.indexTime = timeline.savedindexTime
            timeline.offsetTime = timeline.savedoffsetTime 
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
    timeline.buttonsBackground.size = Number2(38, 210-(38*2))
    timeline.buttonsBackground.pos = Number2(Screen.Width - 200-30-38, 48)

    timeline.horizontalLines = {}

    for i=1, 6 do
        timeline.horizontalLines[i] = ui:createFrame(Color(0, 0, 0, 0.2))
        timeline.horizontalLines[i].size = Number2(timeline.background.Width-38, 5)
        timeline.horizontalLines[i].pos = Number2(10, 10 + (41*(i-1)))
    end

    timeline.lerpTypes = {
        "linear", "quadraticIn", "quadraticOut", "quadraticInOut",
        "cubicIn", "cubicOut", "cubicInOut", "exponentialIn",
        "exponentialOut", "exponentialInOut", "circleIn",
        "circleOut", "circleInOut"
    }
    timeline.lerpButtons = {}

    for i=1, #timeline.lerpTypes do
        timeline.lerpButtons[i] = ui:createButton(timeline.lerpTypes[i], {borders = false, shadow = false})
        timeline.lerpButtons[i].pos = Number2(-1000, -1000)
        timeline.lerpButtons[i].Width = 200
        timeline.lerpButtons[i].onRelease = function()
            timeline.lerpChangeButton:enable()
            selectedInterp = timeline.lerpTypes[i]
            timeline.lerpText.Text = "Interpolation: \n" .. selectedInterp
            for i=1, #timeline.lerpTypes do
                timeline.lerpButtons[i].pos = Number2(-1000, -1000)
            end
        end
    end

    timeline.lerpText = ui:createText("Interpolation: \n" .. selectedInterp, Color(220, 220, 220))
    timeline.lerpText.pos = Number2(Screen.Width - 200-20, 230-38-3-24*2)

    timeline.lerpChangeButton = ui:createButton("Edit", {borders = false, shadow = false, color = Color(46, 46, 46, 0.6), colorPressed = Color(26, 26, 26, 0.6)})
    timeline.lerpChangeButton.pos = Number2(Screen.Width - 220, 20+38+5+38+5)
    timeline.lerpChangeButton.Height = 33
    timeline.lerpChangeButton.onRelease = function()
        for i=1, #timeline.lerpTypes do
            timeline.lerpButtons[i].pos = Number2(Screen.Width - 220, 20+38+5+162+((i-1)*36))
            timeline.lerpButtons[i].Width = 200
        end
        timeline.lerpChangeButton:disable()
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

            for k, val in pairs(timeline.animations[selectedAnimation].shapes[v.name].frames) do
                if timeline.keyframes[val] == nil then timeline.keyframes[val] = {} end
                timeline.keyframes[val][k] = ui:createFrame(Color(0, 255, 255))
                local lerptype = timeline.animations[selectedAnimation].shapes[v.name].frames[k].interpolation
                if lerptype == "linear" then
                    timeline.keyframes[val][k].Color = Color(255, 255, 255)
                elseif lerptype == "quadraticIn" then
                    timeline.keyframes[val][k].Color = Color(255, 255, 0)
                elseif lerptype == "quadraticOut" then
                    timeline.keyframes[val][k].Color = Color(255, 255, 50)
                elseif lerptype == "quadraticInOut" then
                    timeline.keyframes[val][k].Color = Color(200, 200, 0)
                elseif lerptype == "cubicIn" then
                    timeline.keyframes[val][k].Color = Color(0, 255, 255)
                elseif lerptype == "cubicOut" then
                    timeline.keyframes[val][k].Color = Color(50, 200, 255)
                elseif lerptype == "cubicInOut" then
                    timeline.keyframes[val][k].Color = Color(0, 200, 200)
                elseif lerptype == "exponentialIn" then
                    timeline.keyframes[val][k].Color = Color(255, 0, 0)
                elseif lerptype == "exponentialOut" then
                    timeline.keyframes[val][k].Color = Color(200, 0, 0)
                elseif lerptype == "exponentialInOut" then
                    timeline.keyframes[val][k].Color = Color(200, 20, 20)
                elseif lerptype == "circleIn" then
                    timeline.keyframes[val][k].Color = Color(0, 255, 0)
                elseif lerptype == "circleOut" then
                    timeline.keyframes[val][k].Color = Color(50, 255, 50)
                elseif lerptype == "circleInOut" then
                    timeline.keyframes[val][k].Color = Color(0, 200, 0)
                end
                timeline.keyframes[val][k].size = Number2(14, 14.5)
                local a = string.gsub(k, "_", "")
                timeline.keyframes[val][k].pos = Number2(273 + tonumber(a)*timeline.stepSize-timeline.frameOffset, timeline.buttons[i].pos.Y + 8)
                timeline.keyframes[val][k].Rotation.Z = math.pi/4
                if timeline.keyframes[val][k].pos.X < 273 or timeline.keyframes[val][k].pos.X > Screen.Width-266 then
                    timeline.keyframes[val][k]:remove()
                    timeline.keyframes[val][k] = nil
                end
            end
        end
    end

    timeline.updateObjects = function()
        if model == nil then return end
        hierarchyActions:applyToDescendants(model,  { includeRoot = true }, function(s)
            if timeline.animations[selectedAnimation].shapes[s.name].frames == nil then
                return
            end
            local left_keyframe = 0
            local right_keyframe = 0

            local keyframes = {}
            for _, text in pairs(timeline.animations[selectedAnimation].shapes[s.name].frames) do
                local a = string.gsub(_, "_", "")
                a = tonumber(a)
                table.insert(keyframes, a)
                if a > right_keyframe then
                    right_keyframe = a
                end
            end
            local invertedKeyframes = {}
            for i=#keyframes, 1, -1 do
                invertedKeyframes[i] = keyframes[i]
            end

            if #keyframes < 2 then
                return
            end

            if timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(timeline.indexTime) .. "_"] ~= nil then
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

            if timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(left_keyframe) .. "_"].rotation ~= nil and 
            timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(right_keyframe) .. "_"].rotation ~= nil then
                local leftrot = Rotation(
                    timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(left_keyframe) .. "_"].rotation["_ex"],
                    timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(left_keyframe) .. "_"].rotation["_ey"],
                    timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(left_keyframe) .. "_"].rotation["_ez"]
                )
                local rightrot = Rotation(
                    timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(right_keyframe) .. "_"].rotation["_ex"],
                    timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(right_keyframe) .. "_"].rotation["_ey"],
                    timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(right_keyframe) .. "_"].rotation["_ez"]
                )
                local leftpos = Number3(
                    timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(left_keyframe) .. "_"].position["_x"],
                    timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(left_keyframe) .. "_"].position["_y"],
                    timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(left_keyframe) .. "_"].position["_z"]
                )
                local rightpos = Number3(
                    timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(right_keyframe) .. "_"].position["_x"],
                    timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(right_keyframe) .. "_"].position["_y"],
                    timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(right_keyframe) .. "_"].position["_z"]
                )
                s.LocalRotation:Slerp(
                    leftrot,
                    rightrot,
                    lerp[timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(left_keyframe) .. "_"].interpolation](time)
                )
                s.LocalPosition:Lerp(
                    leftpos,
                    rightpos,
                    lerp[timeline.animations[selectedAnimation].shapes[s.name].frames[tostring(left_keyframe) .. "_"].interpolation](time)
                )
            end
        end)
    end

    timeline.cursor = ui:createFrame(Color(255, 255, 0))
    timeline.cursor.size = Number2(11, 12)
    timeline.cursor.pos = Number2(265, 215)
    timeline.cursor.onPress = function() return end
    timeline.cursor.onDrag = function(self, pe)
        local x = math.floor(pe.X * Screen.Width)
        local y = math.floor(pe.Y * Screen.Width)

        timeline.selectedTime = math.min(math.max(0, (x)-270), timeline.background.Width-295) // timeline.stepSize * timeline.stepSize
        timeline.indexTime = (timeline.selectedTime+timeline.frameOffset) // timeline.stepSize
        timeline.cursorLine.pos.X = timeline.selectedTime + 270
        timeline.cursor.pos.X = timeline.selectedTime + 267
        if not timeline.updated then
            timeline.updateObjects()
            timeline.updateTime()
        end
        timeline.updated = true
    end

    timeline.cursorLine = ui:createFrame(Color(255, 255, 255, 0.6))
    timeline.cursorLine.size = Number2(5, 200)
    timeline.cursorLine.pos = Number2(268, 15)

    timeline.animationSelector = ui:createFrame(Color(0, 0, 0, 0.5))
    timeline.animationSelector.size = Number2(260, 190+32)
    timeline.animationSelector.pos = Number2(10, 230)
    timeline.animationSelector.onPress = function() return end

    timeline.animationSelector.text = ui:createText("Animations", Color(255, 255, 255))
    timeline.animationSelector.text.pos = Number2(10 + 260/2 - (timeline.animationSelector.text.Width / 2), 230 - 5 + 190+32 - timeline.animationSelector.text.Height)

    timeline.animationSelector.buttons = {}

    timeline.animationSelector.moveIndex = 0

    timeline.updateAnimations = function()
        for k, v in pairs(timeline.animationSelector.buttons) do
            if timeline.animationSelector.buttons[k] ~= nil then
                timeline.animationSelector.buttons[k].pos = Number2(-1000, -1000)
            end
        end

        local index = 1

        for k, v in pairs(timeline.animations) do
            if index - timeline.animationSelector.moveIndex > 0 and index < timeline.animationSelector.moveIndex + 6 then
                timeline.animationSelector.buttons[k].pos = Number2(15, 416 - (index - timeline.animationSelector.moveIndex) * 36)
            end
            
            index = index + 1
        end

        timeline.animations[selectedAnimation].playSpeed = playSpeed
    end

    timeline.createAnimationButton = ui:createButton("Create", {
        color = Color(0, 0, 0, 0.6), colorPressed = Color(30, 30, 30, 0.6),
        borders = false, shadow = false
    })

    timeline.createAnimationButton.pos = Number2(10, 457)
    timeline.createAnimationButton.Height = 36
    timeline.createAnimationButton.onRelease = function()
        if selectedAnimation == nil then
            print("❌ Animations are not loaded. Please load model first.")
            return
        end

        timeline.createAnimationButton:disable()

        timeline.createAnimationEdit = ui:createTextInput("animation_" .. math.random(1000, 9999), "animation name")
        timeline.createAnimationEdit.Width = 260 - 38
        timeline.createAnimationEdit.pos = Number2(10, 498)

        timeline.createAnimationOk = ui:createButton("✅", {
            color = Color(0, 0, 0, 0.6), colorPressed = Color(30, 30, 30, 0.6),
            borders = false, shadow = false
        })
        timeline.createAnimationOk.pos = Number2(270-38, 498)
        timeline.createAnimationOk.Width = 38 timeline.createAnimationOk.Height = 38
        timeline.createAnimationOk.onRelease = function()
            if timeline.createAnimationEdit.Text == nil then
                timeline.createAnimationEdit.Text = "animation_" .. math.random(1000, 9999)
            end
            selectedAnimation = timeline.createAnimationEdit.Text

            timeline.animationSelector.buttons[selectedAnimation] = ui:createButton(selectedAnimation, {
                color = Color(0, 0, 0, 0.6), colorPressed = Color(30, 30, 30, 0.6),
                borders = false, shadow = false
            })
            timeline.animationSelector.buttons[selectedAnimation].Height = 36
            timeline.animationSelector.buttons[selectedAnimation].Width = 250
            timeline.animationSelector.buttons[selectedAnimation].animation = selectedAnimation

            timeline.animationSelector.buttons[selectedAnimation].onRelease = function(self)
                selectedAnimation = self.animation
                timeline.indexTime = 0
                timeline.offsetTime = 0
                timeline.cursorLine.pos.X = 268
                timeline.cursor.pos.X = 267

                timeline.update()
                timeline.updateTime()
                timeline.updateAnimations()
                timeline.updateObjects()
            end

            timeline.indexTime = 0
            timeline.offsetTime = 0
            timeline.cursorLine.pos.X = 268
            timeline.cursor.pos.X = 267

            timeline.animations[selectedAnimation] = {
                shapes = {},
                maxTime = 0,
                playSpeed = 12
            }
            
            hierarchyActions:applyToDescendants(model,  { includeRoot = true }, function(s)
                timeline.animations[selectedAnimation].shapes[s.name] = {
                    frames = {}
                }
            end)

            timeline.update()
            timeline.updateObjects()
            timeline.updateTime()
            timeline.updateAnimations()
            
            timeline.createAnimationButton:enable()

            timeline.createAnimationEdit:remove()
            timeline.createAnimationEdit = nil

            timeline.createAnimationOk:remove()
            timeline.createAnimationOk = nil
        end
    end

    timeline.removeAnimationButton = ui:createButton("Remove", {
        color = Color(0, 0, 0, 0.6), colorPressed = Color(30, 30, 30, 0.6),
        borders = false, shadow = false
    })
    timeline.removeAnimationButton.pos = Number2(270-86, 457)
    timeline.removeAnimationButton.Height = 36
    timeline.removeAnimationButton.onRelease = function()
        local count = 0

        for k, v in pairs(timeline.animations) do
            count = count + 1
        end

        if selectedAnimation ~= nil and count > 1 then
            if selectedAnimation == "default" then
                print("❌ Cannot remove default animation.")

                return
            end

            timeline.animationSelector.buttons[selectedAnimation]:remove()
            timeline.animationSelector.buttons[selectedAnimation] = nil
            timeline.animations[selectedAnimation] = nil

            selectedAnimation = "default"

            timeline.update()
            timeline.updateObjects()
            timeline.updateTime()
            timeline.updateAnimations()
        end
    end

    timeline.animationSelector.downButton = ui:createButton("⬇", {borders = false, shadow = false, color = Color(46, 46, 46, 0.6), colorPressed = Color(26, 26, 26, 0.6)})
    timeline.animationSelector.downButton.pos = Number2(96+8, 457)
    timeline.animationSelector.downButton.Height = 36 timeline.animationSelector.downButton.Width = 36
    timeline.animationSelector.downButton.onRelease = function()
        local count = 0

        for k, v in pairs(timeline.animationSelector.buttons) do
            count = count + 1
        end

        if timeline.animationSelector.moveIndex < count - 5 then
            timeline.animationSelector.moveIndex = timeline.animationSelector.moveIndex + 1
            timeline.updateAnimations()
        end
    end
    
    timeline.animationSelector.upButton = ui:createButton("⬆", {borders = false, shadow = false, color = Color(46, 46, 46, 0.6), colorPressed = Color(26, 26, 26, 0.6)})
    timeline.animationSelector.upButton.pos = Number2(96+36+8, 457)
    timeline.animationSelector.upButton.Height = 36 timeline.animationSelector.upButton.Width = 36
    timeline.animationSelector.upButton.onRelease = function()
        if timeline.animationSelector.moveIndex > 0 then
            timeline.animationSelector.moveIndex = timeline.animationSelector.moveIndex - 1
            timeline.updateAnimations()
        end
    end
end

loadModel = function(model, loading)
    if model == nil then
        return
    end

    model:SetParent(World)
    loadedModel = model
    timeline.currentId = 0

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

    for k, v in pairs(timeline.animationSelector.buttons) do
        timeline.animationSelector.buttons[k]:remove()
        timeline.animationSelector.buttons[k] = nil
    end

    selectedAnimation = "default"

    if not loading then
        for k, v in ipairs(timeline.animations) do
            timeline.animations[k]:remove()
            timeline.animations[k] = nil
        end

        timeline.animations["default"] = {
            shapes = {},
            maxTime = 0,
        }
    end

    timeline.animationSelector.buttons["default"] = ui:createButton(selectedAnimation, {
        color = Color(0, 0, 0, 0.6), colorPressed = Color(30, 30, 30, 0.6),
        borders = false, shadow = false
    })
    timeline.animationSelector.buttons["default"].Height = 36
    timeline.animationSelector.buttons["default"].Width = 250
    timeline.animationSelector.buttons["default"].onRelease = function()
        selectedAnimation = "default"
        timeline.indexTime = 0
        timeline.offsetTime = 0
        timeline.cursorLine.pos.X = 268
        timeline.cursor.pos.X = 267

        timeline.update()
        timeline.updateTime()
        timeline.updateAnimations()
        timeline.updateObjects()
    end

    hierarchyActions:applyToDescendants(model,  { includeRoot = true }, function(s)
        table.insert(timeline.shapes, s)
        
        local parent = s:GetParent()
        if parent.depth == nil then parent.depth = -1 end
        s.depth = parent.depth + 1
        s.Physics = PhysicsMode.StaticPerBlock

        s.defaultPosition = Number3(s.LocalPosition.X, s.LocalPosition.Y, s.LocalPosition.Z)
        s.defaultRotation = Rotation(s.LocalRotation.X, s.LocalRotation.Y, s.LocalRotation.Z)

        s.addKeyframe = function(self, time, interp)
            if timeline.animations[selectedAnimation].shapes[self.name].frames[tostring(time) .. "_"] == nil then
                timeline.animations[selectedAnimation].shapes[self.name].frames[tostring(time) .. "_"] = {
                    position = Number3(s.LocalPosition.X, s.LocalPosition.Y, s.LocalPosition.Z),
                    rotation = Rotation(s.LocalRotation.X, s.LocalRotation.Y, s.LocalRotation.Z),
                    interpolation = interp
                }
                checkforKeyframe(time)
            else
                self:removeKeyframe(time)
                timeline.animations[selectedAnimation].shapes[self.name].frames[tostring(time) .. "_"] = {
                    position = Number3(s.LocalPosition.X, s.LocalPosition.Y, s.LocalPosition.Z),
                    rotation = Rotation(s.LocalRotation.X, s.LocalRotation.Y, s.LocalRotation.Z),
                    interpolation = interp
                }
                checkforKeyframe(time)
            end

            timeline.update()
        end

        s.removeKeyframe = function(self, time)
            timeline.animations[selectedAnimation].shapes[self.name].frames[tostring(time) .. "_"] = nil

            timeline.update()
        end
    end)

    for k, v in ipairs(timeline.shapes) do
        local name = v.Name
        if name == nil then
            name = ("shape_")
            timeline.currentId = timeline.currentId + 1
        end
        v.name = name .. #timeline.buttons
        timeline.buttons[k] = ui:createButton(name .. timeline.currentId .." [#" .. #timeline.buttons .. "]", {borders = false, color = Color(0.2, 0.2, 0.2, 0.3), colorPressed = Color(0.3, 0.3, 0.3, 0.3), shadow = false})
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

        timeline.animations[selectedAnimation].shapes[v.name] = {name = v.name, frames = {}}
    end

    timeline.update()
    timeline.updateAnimations()
    timeline.updateTime()
end

createLerps = function()
    lerp = {}

    lerp.linear = function(t) return t end
    lerp.quadraticIn = function(t) return t * t end
    lerp.cubicIn = function(t) return t * t * t end
    lerp.quadraticOut = function(t) return t * (2 - t) end
    lerp.cubicOut = function(t) return 1 - (1 - t) ^ 3 end

    -- Additional interpolation functions
    lerp.quadraticInOut = function(t)
        if t < 0.5 then
            return 2 * t * t
        else
            return -1 + (4 - 2 * t) * t
        end
    end

    lerp.cubicInOut = function(t)
        if t < 0.5 then
            return 4 * t * t * t
        else
            return (t - 1) * (2 * t - 2) * (2 * t - 2) + 1
        end
    end

    lerp.exponentialIn = function(t)
        return t == 0 and 0 or 2^(10 * (t - 1))
    end

    lerp.exponentialOut = function(t)
        return t == 1 and 1 or 1 - 2^(-10 * t)
    end

    lerp.exponentialInOut = function(t)
        if t == 0 then return 0 end
        if t == 1 then return 1 end
        if t < 0.5 then
            return 2^(20 * t - 10) / 2
        else
            return (2 - 2^(-20 * t + 10)) / 2
        end
    end

    lerp.circleIn = function(t)
        return 1 - math.sqrt(1 - t * t)
    end

    lerp.circleOut = function(t)
        return math.sqrt(1 - (t - 1) * (t - 1))
    end

    lerp.circleInOut = function(t)
        if t < 0.5 then
            return (1 - math.sqrt(1 - 4 * t * t)) / 2
        else
            return (math.sqrt(1 - (2 * t - 2) * (2 * t - 2)) + 1) / 2
        end
    end

    -- Clamps the value of t between 0 and 1
    local function clamp(t)
        if t < 0 then return 0 end
        if t > 1 then return 1 end
        return t
    end

    lerp.interpolate = function(a, b, t, type)
        t = clamp(t)
        t = lerp[type](t)
        return a * (1 - t) + b * t
    end
end

checkforKeyframe = function(time)
    if timeline.animations[selectedAnimation].maxTime < time then
        timeline.animations[selectedAnimation].maxTime = time
    end
end