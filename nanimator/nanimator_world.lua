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
    --Player:SetParent(nil)

    createUI()
    createLocalEvents()
    aGizmo:setLayer(2)
    gizmo = aGizmo:create({
		orientation = 1,
		moveSnap = 0.5,
	})
    gizmo:setMode(aGizmo.Mode.Rotate)
    gizmo:setOnRotateEnd(function()
        gizmo:setObject(nil)
        gizmo:setObject(selectedObject)
    end)
    Camera.Layers = {1, 2}
end

Client.Tick = function()
    Camera.Rotation.Z = 0

    Camera.Position = Camera.Position + Camera.Forward*globalDy + Camera.Right*globalDx
    if shiftPressed then Camera.Position = Camera.Position + Number3(0, -1, 0) end
    if spacePressed then Camera.Position = Camera.Position + Number3(0, 1, 0) end
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
    timeline.stepSize = 10

    timeline.background = ui:createFrame(Color(0, 0, 0, 0.5))
    timeline.background.size = Number2(Screen.Width - 40 - 200, 210)
    timeline.background.pos = Number2(10, 10)
    timeline.background.onPress = function() return end

    timeline.background.onDrag = function(self, pe)
        local x = math.floor(pe.X * Screen.Width)
        local y = math.floor(pe.Y * Screen.Width)

        timeline.selectedTime = math.min(math.max(0, (x)-270), timeline.background.Width-295) // timeline.stepSize * timeline.stepSize
        timeline.cursorLine.pos.X = timeline.selectedTime + 270
        timeline.cursor.pos.X = timeline.selectedTime + 267
        timeline.time.Text = "Time: " .. string.format("%.0f", timeline.selectedTime/timeline.stepSize) .. "/" .. timeline.maxTime
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

    timeline.upButton = ui:createButton("⬆")
    timeline.upButton.pos = Number2(Screen.Width - 200-30-36, 10+210-36)
    timeline.upButton.onRelease = function()
        if scrollNumber > 1 then
            scrollNumber = scrollNumber - 1
        end
        timeline.update()
    end

    timeline.downButton = ui:createButton("⬇")
    timeline.downButton.pos = Number2(Screen.Width - 200-30-36, 10)
    timeline.downButton.onRelease = function()
        if scrollNumber < #timeline.shapes-4 then
            scrollNumber = scrollNumber + 1
        end
        timeline.update()
    end

    timeline.rotateButton = ui:createButton("↻")
    timeline.rotateButton.pos = Number2(Screen.Width - 220, 20)
    timeline.rotateButton.onRelease = function()
        gizmo:setMode(aGizmo.Mode.Rotate)
    end

    timeline.moveButton = ui:createButton("⇢")
    timeline.moveButton.pos = Number2(Screen.Width - 220 + 36, 20)
    timeline.moveButton.onRelease = function()
        gizmo:setMode(aGizmo.Mode.Move)
    end

    timeline.localButton = ui:createButton("🏠")
    timeline.localButton.pos = Number2(Screen.Width - 220 + 36*2 + 5, 20)
    timeline.localButton.onRelease = function()
        gizmo:setOrientation(aGizmo.Orientation.Local)
    end

    timeline.globalButton = ui:createButton("🌎")
    timeline.globalButton.pos = Number2(Screen.Width - 220 + 36*3 + 5, 20)
    timeline.globalButton.onRelease = function()
        gizmo:setOrientation(aGizmo.Orientation.World)
    end

    timeline.resetButton = ui:createButton("🔁")
    timeline.resetButton.pos = Number2(Screen.Width - 20-36, 20)
    timeline.resetButton.onRelease = function()
        selectedObject.LocalRotation = selectedObject.defaultRotation
        selectedObject.LocalPosition = selectedObject.defaultPosition
    end

    timeline.buttonsBackground = ui:createFrame(Color(0, 0, 0, 0.4))
    timeline.buttonsBackground.size = Number2(36, 210-(36*2))
    timeline.buttonsBackground.pos = Number2(Screen.Width - 200-30-36, 46)

    timeline.horizontalLines = {}

    for i=1, 6 do
        timeline.horizontalLines[i] = ui:createFrame(Color(0, 0, 0, 0.2))
        timeline.horizontalLines[i].size = Number2(timeline.background.Width-36, 5)
        timeline.horizontalLines[i].pos = Number2(10, 10 + (41*(i-1)))
    end

    timeline.update = function()
        for k, v in ipairs(timeline.buttons) do
            timeline.buttons[k].pos = Number2(-1000, -1000)
            timeline.buttons[k].line.pos = Number2(-1000, -1000)
            timeline.buttons[k].line2.pos = Number2(-1000, -1000)
            if timeline.buttons[k].line3 ~= nil then
                timeline.buttons[k].line3.pos = Number2(-1000, -1000)
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
        end
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

    hierarchyActions:applyToDescendants(model,  { includeRoot = true }, function(s)
        table.insert(timeline.shapes, s)
        
        local parent = s:GetParent()
        if parent.depth == nil then parent.depth = -1 end
        s.depth = parent.depth + 1
        s.Physics = PhysicsMode.StaticPerBlock

        s.defaultPosition = Number3(s.LocalPosition.X, s.LocalPosition.Y, s.LocalPosition.Z)
        s.defaultRotation = Rotation(s.LocalRotation.X, s.LocalRotation.Y, s.LocalRotation.Z)
    end)

    for k, v in ipairs(timeline.shapes) do
        local name = v.Name
        if name == nil or name == "(null)" then name = "Shape " .. math.random(1000, 9999) end
        timeline.buttons[k] = ui:createButton(name, {borders = false, color = Color(0.2, 0.2, 0.2, 0.3), colorPressed = Color(0.3, 0.3, 0.3, 0.3), shadow = false})
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
    end

    timeline.update()
end