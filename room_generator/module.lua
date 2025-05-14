local mod = {}

local SEED = 1337
local MAP_WIDTH = 80
local MAP_HEIGHT = 40
local ROOM_MIN = 4
local ROOM_MAX = 8

-- Initialize map
local function mod.createMap(w, h)
    local map = {}
    for y = 1, h do
        map[y] = {}
        for x = 1, w do
            map[y][x] = '#'
        end
    end
    return map
end

-- Carve a room in the map
local function mod.carveRoom(map, x, y, w, h)
    for j = y, y + h - 1 do
        for i = x, x + w - 1 do
            if j > 0 and j <= MAP_HEIGHT and i > 0 and i <= MAP_WIDTH then
                map[j][i] = '.'
            end
        end
    end
end

-- Maze-like dense grid
local function mod.generateSeamlessRooms()
    local map = createMap(MAP_WIDTH, MAP_HEIGHT)

    local gridRows = math.floor(MAP_HEIGHT / ROOM_MAX)
    local gridCols = math.floor(MAP_WIDTH / ROOM_MAX)

    for gy = 0, gridRows - 1 do
        for gx = 0, gridCols - 1 do
            local rw = math.random(ROOM_MIN, ROOM_MAX)
            local rh = math.random(ROOM_MIN, ROOM_MAX)
            local rx = gx * ROOM_MAX + 1 + math.random(0, ROOM_MAX - rw)
            local ry = gy * ROOM_MAX + 1 + math.random(0, ROOM_MAX - rh)

            carveRoom(map, rx, ry, rw, rh)

            -- Optionally connect to neighbor
            if gx > 0 and math.random() < 0.8 then
                local cx = rx - 1
                local cy = ry + math.random(0, rh - 1)
                map[cy][cx] = '.'
            end
            if gy > 0 and math.random() < 0.8 then
                local cx = rx + math.random(0, rw - 1)
                local cy = ry - 1
                map[cy][cx] = '.'
            end
        end
    end

    return map
end

-- Render to terminal
local function mod.printMap(map)
    for y = 1, #map do
        local row = ""
        for x = 1, #map[y] do
            row = row .. map[y][x]
        end
        print(row)
    end
end

local function mod.get_map()
    return generateSeamlessRooms()
end

return mod