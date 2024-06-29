local nanimator = {}

nanimator.animations = {}

nanimator.import = function(data, name)
    if data == nil or type(data) ~= "string" then
        error("Invalid animation data. Did you import a valid animation data text?", 3)

        return
    end

    local decoded = JSON:Decode(data)
    if decoded.shape == nil or type(decoded.shape) ~= "string" then
        error("Invalid animation data. Missing shape.", 3)

        return
    end
    if decoded.animations == nil or type(decoded.animations) ~= "table" then
        error("Invalid animation data. Missing animation.", 3)

        return
    end

    nanimator.animations[name] = decoded
end

nanimator.add = function(object, name)
    if nanimator.animations[name] == nil then
        error("Animation not found: ".. name, 3)

        return
    end
    hierarchyActions = require("hierarchyactions")

    if type(object) == "Player" then
        object = object.Body

        print("⚠️ nanimator.add(): can't add animation to a Player object. Animation added to a Player.Body")
    end

    if object.nanplayer == nil then
        object.nanplayer = Object()
        object.nanplayer:SetParent(object)
        object.nanplayer.animations = {}
        object.nanplayer.animations[name] = nanimator.animations[name]
        object.nanplayer.currentAnimation = name
        object.nanplayer.currentFrame = 0
        object.nanplayer.loop = false
        object.nanplayer.playing = false
        object.nanplayer.shapes = {}
        object.nanplayer.animationKey = "default" -- default animation key, should be changed to change animation sequence
        object.nanplayer.playSpeed = 1

        local currentId = 0

        hierarchyActions:applyToDescendants(object,  { includeRoot = true }, function(s)
            local name = s.Name
            if type(s) ~= "Shape" and type(s) ~= "MutableShape" then
                return
            end
            if name == nil or name == "(null)" then
                name = "shape_"
            end
            s.name = name .. currentId
            currentId = currentId + 1
        end)

        object.nanplayer.Tick = function(self, dt)
            local parent = self:GetParent()
            if parent == nil then
                self:remove()

                return
            end

            if self.playing then
                self.dt = dt
                self:animate()
            end
        end

        object.nanplayer.animate = function(self)
            if self == nil then
                error([[self:animate() must be executed with ":"!]], 3)

                return
            end

            hierarchyActions:applyToDescendants(self:GetParent(),  { includeRoot = true }, function(s)

                if type(s) ~= "Shape" and type(s) ~= "MutableShape" then
                    return
                end

                local left_keyframe = 0
                local right_keyframe = 0
    
                local keyframes = {}

                if self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames == nil then return end
                
                for _, text in pairs(self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames) do
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
    
                if self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames[tostring(self.currentFrame) .. "_"] ~= nil then
                    left_keyframe = self.currentFrame
                    right_keyframe = self.currentFrame
                else
                    for _, keyframe in ipairs(keyframes) do
                        if keyframe < self.currentFrame and keyframe > left_keyframe then
                            left_keyframe = keyframe
                        end
                    end
                    for _, keyframe in ipairs(invertedKeyframes) do
                        if keyframe > self.currentFrame and keyframe < right_keyframe  then
                            right_keyframe = keyframe
                        end
                    end
                end
    
                local time = 0
                if left_keyframe ~= nil and right_keyframe ~= nil and right_keyframe ~= left_keyframe then
                    time = (self.currentFrame - left_keyframe) / (right_keyframe - left_keyframe)
                end
    
                if self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames[tostring(left_keyframe) .. "_"].rotation ~= nil and 
                self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames[tostring(right_keyframe) .. "_"].rotation ~= nil then
                    local leftrot = Rotation(
                        self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames[tostring(left_keyframe) .. "_"].rotation["_ex"],
                        self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames[tostring(left_keyframe) .. "_"].rotation["_ey"],
                        self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames[tostring(left_keyframe) .. "_"].rotation["_ez"]
                    )
                    local rightrot = Rotation(
                        self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames[tostring(right_keyframe) .. "_"].rotation["_ex"],
                        self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames[tostring(right_keyframe) .. "_"].rotation["_ey"],
                        self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames[tostring(right_keyframe) .. "_"].rotation["_ez"]
                    )
                    local leftpos = Number3(
                        self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames[tostring(left_keyframe) .. "_"].position["_x"],
                        self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames[tostring(left_keyframe) .. "_"].position["_y"],
                        self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames[tostring(left_keyframe) .. "_"].position["_z"]
                    )
                    local rightpos = Number3(
                        self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames[tostring(right_keyframe) .. "_"].position["_x"],
                        self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames[tostring(right_keyframe) .. "_"].position["_y"],
                        self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames[tostring(right_keyframe) .. "_"].position["_z"]
                    )

                    local pos = Number3(0, 0, 0)
                    local rot = Rotation(0, 0, 0)

                    if type(s:GetParent()) == "World" then
                        pos = s.basePos
                        rot = s.baseRot
                    end

                    s.LocalRotation:Slerp(
                        leftrot + rot,
                        rightrot + rot,
                        nanimator.lerp[self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames[tostring(left_keyframe) .. "_"].interpolation](time)
                    )
                    s.LocalPosition:Lerp(
                        leftpos + pos,
                        rightpos + pos,
                        nanimator.lerp[self.animations[self.currentAnimation].animations[self.animationKey].shapes[s.name].frames[tostring(left_keyframe) .. "_"].interpolation](time)
                    )
                end
            end)

            local delta = self.dt*62.5
            local frame = (delta*(self.animations[self.currentAnimation].animations[self.animationKey].playSpeed * self.playSpeed or 12))/62.5

            self.currentFrame = self.currentFrame + frame
            if self.currentFrame > self.animations[self.currentAnimation].animations[self.animationKey].maxTime then
                self.currentFrame = 0
                if not self.loop then
                    self.playing = false
                end
            end
        end

        object.nanplayer.remove = function(self)
            print("removed")
            local parent = self:GetParent().nanplayer
            parent.animations = nil
            parent.currentAnimation = nil
            parent.Tick = nil

            parent:SetParent(nil)
            parent = nil
        end

        object.nanPlay = function(self, name, anim)
            if self == nil then
                error([[self:nanPlay() must be executed with ":"!]], 3)

                return
            end
            if name ~= nil then
                self.nanplayer.animations[name] = nanimator.animations[name]
            end
            if name == nil then
                name = self.nanplayer.currentAnimation
            end
            if anim ~= nil then
                self.nanplayer.animationKey = anim
            end
            if self.nanplayer.animationKey == nil then
                self.nanplayer.animationKey = "default"
            end
            if self.nanplayer.animations[name] == nil then
                error("Animation not found: ".. name, 3)
        
                return
            end

            hierarchyActions:applyToDescendants(self:GetParent(),  { includeRoot = true }, function(s)
                s.baseRot = Rotation(s.LocalRotation.X, s.LocalRotation.Y, s.LocalRotation.Z)
                s.basePos = Number3(s.LocalPosition.X, s.LocalPosition.Y, s.LocalPosition.Z)
            end)

            self.nanplayer.playing = true
        end

        object.setLoop = function(self, bool)
            if self == nil or type(self) == "boolean" then
                error([[object.setLoop(boolean) should be called with ":"!]])
            end
            if bool == nil or type(bool) ~= "boolean" then
                error([[object.setLoop(boolean) should receive a boolean value.]])
            end

            self.nanplayer.loop = bool
        end

        object.getKeyframe = function(self)
            if self == nil then
                error([[object.getKeyframe() should be called with ":"!]])
            end

            return self.nanplayer.currentFrame
        end

        object.getAnimation = function(self)
            if self == nil then
                error([[object.getAnimation() should be called with ":"!]])
            end

            return self.nanplayer.animationKey
        end

        object.getPlaySpeed = function(self)
            if self == nil then
                error([[object.getPlaySpeed() should be called with ":"!]])
            end

            return self.nanplayer.playSpeed
        end

        object.getLoop = function(self)
            if self == nil then
                error([[object.getKeyframe() should be called with ":"!]])
            end

            return self.nanplayer.loop
        end

        object.setPlaySpeed = function(self, speed)
            if self == nil or type(self) == "number" or type(self) == "integer" then
                error([[object.setPlaySpeed(speed) should be called with ":"!]])
            end

            self.nanplayer.playSpeed = speed
        end
    end
end

nanimator.lerp = {}

nanimator.lerp.linear = function(t) return t end
nanimator.lerp.quadraticIn = function(t) return t * t end
nanimator.lerp.cubicIn = function(t) return t * t * t end
nanimator.lerp.quadraticOut = function(t) return t * (2 - t) end
nanimator.lerp.cubicOut = function(t) return 1 - (1 - t) ^ 3 end

nanimator.lerp.quadraticInOut = function(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return -1 + (4 - 2 * t) * t
    end
end

nanimator.lerp.cubicInOut = function(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        return (t - 1) * (2 * t - 2) * (2 * t - 2) + 1
    end
end

nanimator.lerp.exponentialIn = function(t)
    return t == 0 and 0 or 2^(10 * (t - 1))
end

nanimator.lerp.exponentialOut = function(t)
    return t == 1 and 1 or 1 - 2^(-10 * t)
end

nanimator.lerp.exponentialInOut = function(t)
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    if t < 0.5 then
        return 2^(20 * t - 10) / 2
    else
        return (2 - 2^(-20 * t + 10)) / 2
    end
end

nanimator.lerp.circleIn = function(t)
    return 1 - math.sqrt(1 - t * t)
end

nanimator.lerp.circleOut = function(t)
    return math.sqrt(1 - (t - 1) * (t - 1))
end

nanimator.lerp.circleInOut = function(t)
    if t < 0.5 then
        return (1 - math.sqrt(1 - 4 * t * t)) / 2
    else
        return (math.sqrt(1 - (2 * t - 2) * (2 * t - 2)) + 1) / 2
    end
end

-- Clamps the value of t between 0 and 1
nanimator.clamp = function(t)
    if t < 0 then return 0 end
    if t > 1 then return 1 end
    return t
end

nanimator.lerp.interpolate = function(a, b, t, type)
    t = nanimator.clamp(t)
    t = nanimator.lerp[type](t)
    return a * (1 - t) + b * t
end

return nanimator