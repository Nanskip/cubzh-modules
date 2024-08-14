local hex = {}

local function hexToRgb(hex)
    -- Remove the hash if it exists
    if hex == nil or type(hex) ~= "string" then
        error("hex() - 1st argument should be a string.")
    end
    hex = hex:gsub("^#", "")
    
    -- Check if the HEX code is valid
    if #hex ~= 6 then
        error("Invalid HEX color code")
    end
    
    -- Convert HEX to RGB values
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    
    return Color(r, g, b)
end

local hex_mt = {
    __call = function(self, hex_code)
        return hexToRgb(hex_code)
    end
}

setmetatable(hex, hex_mt)

return hex