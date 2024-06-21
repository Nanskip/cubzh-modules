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

        print(selectedObject)
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
    --stolen from S&Cubzh 2 by fab3kleuuu
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
            print("Model name: " .. cell.itemFullName)

            Object:Load(cell.itemFullName, function(self)
                if model ~= nil then
                    model:SetParent(nil)
                end
                model = self
                model:SetParent(World)
            end)
            items_gallery:close()
        end
    end

    timeline = Object()
    timeline.background = ui:createFrame(Color(0, 0, 0, 0.5))
    timeline.background.size = Number2(Screen.Width - 40 - 200, 200)
    timeline.background.pos = Number2(10, 10)
    timeline.background.onPress = function() return end

    animationSelector = Object()
    animationSelector = ui:createFrame(Color(0, 0, 0, 0.5))
    animationSelector.size = Number2(260, 320)
    animationSelector.pos = Number2(10, 220)
    animationSelector.onPress = function() return end
end