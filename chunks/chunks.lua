--local chunks = {}
chunks = {}

chunks.scale = Number3(2, 2, 2)
chunks.map = Map
chunks.table = {}

function chunks.fill(position)
    if position == nil then
        error("chunks.fill(): position is nil.")
    end
    for x = 1, chunks.scale.X do
        chunks.table[x+position.X*chunks.scale.X] = {}
        for y = 1, chunks.scale.Y do
            chunks.table[x+position.X*chunks.scale.X][y+position.Y*chunks.scale.Y] = {}
            for z = 1, chunks.scale.Z do
                --if math.random(0, 1) == 1 then
                local pos = Number3(x, y, z) + Number3(position.X*chunks.scale.X, position.Y*chunks.scale.Y, position.Z*chunks.scale.Z)
                local block = Block(Color(255, 255, 255, 0), pos)

                local blockObject = Object()
                blockObject.Position = pos
                chunks.table[x+position.X*chunks.scale.X][y+position.Y*chunks.scale.Y][z+position.Z*chunks.scale.Z] = blockObject
                chunks.map:AddBlock(block)
                --end
            end
        end
    end

    for x = 1, chunks.scale.X do
        for y = 1, chunks.scale.Y do
            for z = 1, chunks.scale.Z do
                local pos = Number3(x, y, z) + Number3(position.X*chunks.scale.X, position.Y*chunks.scale.Y, position.Z*chunks.scale.Z)

                local dx = x + position.X*chunks.scale.X
                local dy = y + position.Y*chunks.scale.Y
                local dz = z + position.Z*chunks.scale.Z

                if chunks.table[dx][dy][z] ~= nil then
                    if chunks.map:GetBlock(pos + Number3(1, 0, 0)) == nil then
                        chunks.table[x+position.X][y+position.Y][z+position.Z].xplus = Quad()
                        chunks.table[x+position.X][y+position.Y][z+position.Z].xplus.Color = Color(0, 0, 255, 100)
                        chunks.table[x+position.X][y+position.Y][z+position.Z].xplus.Position = (pos + Number3(1, 0, 0))*chunks.map.Scale.X
                        chunks.table[x+position.X][y+position.Y][z+position.Z].xplus.Rotation.Y = -math.pi/2
                        chunks.table[x+position.X][y+position.Y][z+position.Z].xplus.Scale = chunks.map.Scale
                        chunks.table[x+position.X][y+position.Y][z+position.Z].xplus:SetParent(World)
                    end
                    if chunks.map:GetBlock(pos + Number3(-1, 0, 0)) == nil then
                        chunks.table[x+position.X][y+position.Y][z+position.Z].xminus = Quad()
                        chunks.table[x+position.X][y+position.Y][z+position.Z].xminus.Color = Color(255, 0, 0, 100)
                        chunks.table[x+position.X][y+position.Y][z+position.Z].xminus.Position = pos*chunks.map.Scale.X
                        chunks.table[x+position.X][y+position.Y][z+position.Z].xminus.Rotation.Y = -math.pi/2
                        chunks.table[x+position.X][y+position.Y][z+position.Z].xminus.Scale = chunks.map.Scale
                        chunks.table[x+position.X][y+position.Y][z+position.Z].xminus:SetParent(World)
                    end
                    if chunks.map:GetBlock(pos + Number3(0, 1, 0)) == nil then
                        chunks.table[x+position.X][y+position.Y][z+position.Z].yplus = Quad()
                        chunks.table[x+position.X][y+position.Y][z+position.Z].yplus.Color = Color(0, 255, 0, 100)
                        chunks.table[x+position.X][y+position.Y][z+position.Z].yplus.Position = (pos + Number3(0, 1, 0))*chunks.map.Scale.X
                        chunks.table[x+position.X][y+position.Y][z+position.Z].yplus.Rotation.X = math.pi/2
                        chunks.table[x+position.X][y+position.Y][z+position.Z].yplus.Scale = chunks.map.Scale
                        chunks.table[x+position.X][y+position.Y][z+position.Z].yplus:SetParent(World)
                    end
                    if chunks.map:GetBlock(pos + Number3(0, -1, 0)) == nil then
                        chunks.table[x+position.X][y+position.Y][z+position.Z].yminus = Quad()
                        chunks.table[x+position.X][y+position.Y][z+position.Z].yminus.Color = Color(255, 255, 0, 100)
                        chunks.table[x+position.X][y+position.Y][z+position.Z].yminus.Position = pos*chunks.map.Scale.X
                        chunks.table[x+position.X][y+position.Y][z+position.Z].yminus.Rotation.X = math.pi/2
                        chunks.table[x+position.X][y+position.Y][z+position.Z].yminus.Scale = chunks.map.Scale
                        chunks.table[x+position.X][y+position.Y][z+position.Z].yminus:SetParent(World)
                    end
                    if chunks.map:GetBlock(pos + Number3(0, 0, 1)) == nil then
                        chunks.table[x+position.X][y+position.Y][z+position.Z].zplus = Quad()
                        chunks.table[x+position.X][y+position.Y][z+position.Z].zplus.Color = Color(255, 0, 255, 100)
                        chunks.table[x+position.X][y+position.Y][z+position.Z].zplus.Position = (pos + Number3(0, 0, 1))*chunks.map.Scale.X
                        chunks.table[x+position.X][y+position.Y][z+position.Z].zplus.Scale = chunks.map.Scale
                        chunks.table[x+position.X][y+position.Y][z+position.Z].zplus:SetParent(World)
                    end
                    if chunks.map:GetBlock(pos + Number3(0, 0, -1)) == nil then
                        chunks.table[x+position.X][y+position.Y][z+position.Z].zminus = Quad()
                        chunks.table[x+position.X][y+position.Y][z+position.Z].zminus.Color = Color(0, 255, 255, 100)
                        chunks.table[x+position.X][y+position.Y][z+position.Z].zminus.Position = pos*chunks.map.Scale.X
                        chunks.table[x+position.X][y+position.Y][z+position.Z].zminus.Scale = chunks.map.Scale
                        chunks.table[x+position.X][y+position.Y][z+position.Z].zminus:SetParent(World)
                    end
                end
            end
        end
    end
end

--return chunks