--local chunks = {}

chunks = {}

chunks.scale = 256
chunks.map = {}

function chunks.fill(self)
    local map = self.map
    local scale = self.scale
    for x=1, scale do
        map[x] = {}
        Timer(0.01*x, false, function()
            for y=1, scale do
                map[x][y] = {}
                for z=1, scale do
                    local val = perlin.get(x*0.1, y*0.1, z*0.1)
                    local save = 0
                    if val >= 0 then
                        save = 1
                    end
                    map[x][y][z] = save
                end
            end
        end)
    end
end

function chunks.place(self)
    local map = self.map
    local white = Color.White
    for x=1, #map do
        Timer(0.01*x, false, function()
            for y=1, #map[x] do
                for z=1, #map[x][y] do
                    local up = map[x][y+1][z]
                    local down = map[x][y-1][z]
                    local left = map[x-1][y][z]
                    local right = map[x+1][y][z]
                    local front = map[x][y][z+1]
                    local back = map[x][y][z-1]

                    if up ~= 1 or down ~= 1 or left ~= 1 or right ~= 1 or front ~= 1 or back ~= 1 then
                        if map[x][y][z] == 1 then
                            Map:AddBlock(white, x, y, z)
                        end
                    end
                end
            end
        end)
    end
end

--return chunks