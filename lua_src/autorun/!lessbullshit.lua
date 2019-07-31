-- Unfortunately THIS bullshit is necessary.
local oldColor = Color

local function NormalizeColor(r, g, b)
	if r >= 0 and r < 256 and g >= 0 and g < 256 and b >= 0 and b < 256 then
		return r, g, b
	end

	if r < 0 then
		g, b = g - r, b - r
		r = 0
	end

	if g < 0 then
		r, b = r - g, b - g
		g = 0
	end

	if b < 0 then
		r, g = r - b, g - b
		b = 0
	end

	if r >= 0 and r < 256 and g >= 0 and g < 256 and b >= 0 and b < 256 then
		return r, g, b
	end

	local len = math.sqrt(r^2 + g^2 + b^2) / 255

	r = math.Round(r / len)
	g = math.Round(g / len)
	b = math.Round(b / len)

	return r, g, b
end

local __add = function(self, target)
	if not IsColor(self) and IsColor(target) then
		local s1, s2 = self, target
		target = s1
		self = s2
	end

	if type(target) == 'number' then
		newColor = Color(NormalizeColor(self.r + target, self.g + target, self.b + target))
		newColor.a = self.a
		return newColor
	elseif type(target) == 'Vector' then
		newColor = Color(NormalizeColor(self.r + target.x, self.g + target.y, self.b + target.z))
		newColor.a = self.a
		return newColor
	elseif IsColor(target) then
		newColor = Color(NormalizeColor(self.r + target.r, self.g + target, self.b + target))
		newColor.a = self.a
		return newColor
	end
end

local __sub = function(self, target)
	if not IsColor(self) and IsColor(target) then
		local s1, s2 = self, target
		target = s1
		self = s2
	end

	if type(target) == 'number' then
		newColor = Color(NormalizeColor(self.r - target, self.g - target, self.b - target))
		newColor.a = self.a
		return newColor
	elseif type(target) == 'Vector' then
		newColor = Color(NormalizeColor(self.r - target.x, self.g - target.y, self.b - target.z))
		newColor.a = self.a
		return newColor
	elseif (type(target) == "table") and IsColor(target) then
		newColor = Color(NormalizeColor(self.r - target.r, self.g - target, self.b - target))
		newColor.a = self.a
		return newColor
	end
end

local metamodified = false

Color = function(r, g, b, a)
	if type(r) == "table" then
		a = r.a
		b = r.b
		g = r.g
		r = r.r
	end

	r = r or 255
	g = g or 255
	b = b or 255
	a = a or 255

	clr = oldColor(r, g, b, a)
	if not metamodified then
		metamodified = true
		local meta = debug.getmetatable(clr)
		meta.__add = __add
		meta.__sub = __sub
	end

	return clr
end