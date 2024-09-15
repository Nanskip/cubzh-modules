local perlin = {}

-- Initialize permutation table
perlin.permutation = {}

-- Simple deterministic random number generator (Linear Congruential Generator)
function perlin.lcg(seed)
    local current_seed = seed
    return function()
        current_seed = (1103515245 * current_seed + 12345) % 2147483648
        return current_seed / 2147483648
    end
end

-- Function to shuffle permutation table with deterministic randomness
function perlin.shuffle(seed)
    local rand = perlin.lcg(seed)
    for i = 0, 255 do
      perlin.permutation[i] = i
    end
  
    for i = 1, #perlin.permutation do
      local j = math.floor(rand() * (#perlin.permutation-1)) + 1
  
      local a = perlin.permutation[i]
      local b = perlin.permutation[j]
  
      perlin.permutation[i] = b
      perlin.permutation[j] = a
    end
  end

-- Seed the permutation table
function perlin.seed(seed)
    for i = 0, 5 do
        perlin.shuffle(seed)
        -- Duplicate the permutation table to handle index wrapping
    
        for i = 0, 255 do
            perlin.permutation[256 + i] = perlin.permutation[i]
        end
    end
end

-- Function to generate Perlin noise in 3D
function perlin.get(x, y, z)
    x = x % 256
    y = y % 256
	if z == nil then z = 0 end
    z = z % 256

    local X = math.floor(x) % 256
    local Y = math.floor(y) % 256
    local Z = math.floor(z) % 256

    x = x - math.floor(x)
    y = y - math.floor(y)
    z = z - math.floor(z)

    local u = perlin.fade(x)
    local v = perlin.fade(y)
    local w = perlin.fade(z)

    local p = perlin.permutation

    local A  = p[X] + Y
    local AA = p[A] + Z
    local AB = p[A + 1] + Z
    local B  = p[X + 1] + Y
    local BA = p[B] + Z
    local BB = p[B + 1] + Z

    return perlin.lerp(w,
        perlin.lerp(v,
            perlin.lerp(u, perlin.grad(p[AA  ], x  , y  , z   ), perlin.grad(p[BA  ], x-1, y  , z   )),
            perlin.lerp(u, perlin.grad(p[AB  ], x  , y-1, z   ), perlin.grad(p[BB  ], x-1, y-1, z   ))
        ),
        perlin.lerp(v,
            perlin.lerp(u, perlin.grad(p[AA+1], x  , y  , z-1 ), perlin.grad(p[BA+1], x-1, y  , z-1 )),
            perlin.lerp(u, perlin.grad(p[AB+1], x  , y-1, z-1 ), perlin.grad(p[BB+1], x-1, y-1, z-1 ))
        )
    )
end

-- Perlin noise helper functions
function perlin.lerp(t, a, b)
    return a + t * (b - a)
end

function perlin.fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

function perlin.grad(hash, x, y, z)
    local h = hash % 16
    local u = h<8 and x or y
    local v = h<4 and y or (h==12 or h==14) and x or z
    return ((h%2)==0 and u or -u) + ((h%4)<2 and v or -v)
end

-- Seed the permutation table with a random seed
perlin.seed(os.time())
perlin.randomPermutation = function()
	perlin("⚠️ perlin.randomPermutation() is deprecated, use perlin.seed() instead.")
	perlin.seed(os.time())
end

-- Helper functions
function perlin.fade(t)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

return perlin