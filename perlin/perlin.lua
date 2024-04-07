local perlin = {}

-- Function to generate Perlin noise
function perlin.get(x, y)
	x = x % 256
	y = y % 256
	local X = math.floor(x)
	local Y = math.floor(y)
	x = x - math.floor(x)
	y = y - math.floor(y)
	local u = perlin.fade(x)
	local v = perlin.fade(y)

	local p = perlin.permutation
	local A = (p[X] + Y) % 256
	local AA = p[A]
	local AB = p[(A + 1) % 256]
	local B = (p[(X + 1) % 256] + Y) % 256
	local BA = p[B]
	local BB = p[(B + 1) % 256]

	return perlin.lerp(
		v,
		perlin.lerp(u, perlin.grad(p[AA], x, y), perlin.grad(p[BA], x - 1, y)),
		perlin.lerp(u, perlin.grad(p[AB], x, y - 1), perlin.grad(p[BB], x - 1, y - 1))
	)
end

function perlin.lerp(t, a, b)
	return a + t * (b - a)
end

function perlin.grad(hash, x, y)
	local h = hash and (hash & 15) or 0
	local u = h < 8 and x or y
	local v = h < 4 and y or (h == 12 or h == 14) and x or 0
	return ((h & 1) == 0 and u or -u) + ((h & 2) == 0 and v or -v)
end

perlin.randomPermutation = function()
    -- Permutation table (you can use any permutation here)
    perlin.permutation = {}
    for i = 0, 255 do
        perlin.permutation[i] = math.random(0, 255)
    end
end
perlin.randomPermutation()

-- Helper functions
function perlin.fade(t)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

return perlin