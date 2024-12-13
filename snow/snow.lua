local snow = {}

snow.create = function(config)
    local defaultConfig = {
        gravity = 0.5,
        speed = 0.01,
        direction = 0,
        radius = 100,
        height = 100,
        height_randomness = 10,
        maxParticles = 200,
        respawn = 0.2,
        removeOnCollision = true,
    }
    config = config or {}
    for k, v in pairs(defaultConfig) do
        if config[k] == nil then
            config[k] = v
        end
    end

    local spawner = Object()
    spawner.ticks = 0
    spawner.spawned = 0
    spawner.config = config
    spawner.pool = {}
    spawner.Tick = function(self, dt)
        self.ticks = self.ticks + dt
        if self.ticks > self.config.respawn then
            self.ticks = 0
            if self.spawned < self.config.maxParticles then
                local particle = MutableShape()
                particle.Physics = PhysicsMode.Trigger
                particle:AddBlock(Color(255, 255, 255), Number3(0, 0, 0))
                particle.Pivot = Number3(0.5, 0.5, 0.5)
                particle.speed = self.config.speed
                particle.gravity = self.config.gravity
                particle.height = self.config.height
                particle.removeOnCollision = self.config.removeOnCollision
                particle.height_randomness = self.config.height_randomness
                particle.Rotation = Rotation(0, self.config.direction, 0)
                particle.Tick = function(s)
                    s.Position = s.Position + Number3(0, -s.gravity, 0) + (s.Forward * s.speed)
                    if s.Position.Y < -s.height + self.Position.Y then
                        particle:setPos()
                    end
                end
                particle:SetParent(World)
                particle.OnCollisionBegin = function(s, other)
                    if s.removeOnCollision then
                        if other ~= Map then
                            if other.Physics == PhysicsMode.StaticPerBlock or other.Physics == PhysicsMode.Static then
                                particle:setPos()
                            end
                        else
                            particle:setPos()
                        end
                    end
                end

                particle.setPos = function(s)
                    if not self.stopped then
                    s.Position = self.Position + self.config.height +
                        Number3(0, s.height_randomness*math.random(-10, 10)/10, 0) +
                        Number3(
                            math.random(-self.config.radius*10, self.config.radius*10)/10,
                            0,
                            math.random(-self.config.radius*10, self.config.radius*10)/10)
                    else
                        s:SetParent(nil)
                        self.pool[#self.pool + 1] = s
                    end
                end
                particle:setPos()

                self.spawned = self.spawned + 1
            end
        end
    end

    spawner.stop = function(self)
        self.stopped = true
    end

    spawner.start = function(self)
        self.stopped = false

        for i = 1, #self.pool do
            self.pool[i]:setPos()
            self.pool[i]:SetParent(World)
        end
    end

    return spawner
end

--return snow