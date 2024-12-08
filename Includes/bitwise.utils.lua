--=====================================================
-- CopyRight (c) R 2022-2203
--
-- Random (sometimes) useful BIT utils for lua
--
--=====================================================

-------------------
bit = {
	version = "1.0",
	author = "Trey Reynolds, shortcut0",
	description = "all kinds of BIT utility functions that might come in handy"
}

---------------------------
-- bit.XOR

bit.XOR = function(a, b)
	
	--------
	local p, c = 1, 0
	while (a > 0 and b > 0) 
	do
		local ra, rb = (a % 2), (b % 2)
		if (ra ~= rb) then 
			c = c + p end
			
		------
		a, b, p = ((a - ra) / 2), ((b - rb) / 2), (p * 2)
	end
	
	--------
	if (a < b) then 
		a = b end
		
	--------
	while (a > 0) 
	do
		local ra = (a % 2)
		if (ra > 0) then 
			c = c + p end

		------
		a, p = ((a - ra) / 2), (p * 2)
	end
	
	--------
	return c
end

---------------------------
-- bit.OR

bit.OR = function(a, b)
	
	--------
	local p, c = 1, 0
	while (a + b > 0) 
	do
		local ra, rb = (a % 2), (b % 2)
		if (ra + rb > 0) then 
			c = c + p end
			
		------
		a, b, p = ((a - ra) / 2), ((b - rb) / 2), (p * 2)
	end
	
	--------
	return c
end

---------------------------
-- bit.NOT

bit.NOT = function(n)
	
	--------
	local p, c = 1, 0
	while (n > 0) 
	do
		local r = (n % 2)
		if (r < 1) then 
			c = c + p end
			
		------
		n, p = ((n - r) / 2), (p * 2)
	end
	
	--------
	return c
end

---------------------------
-- bit.AND

bit.AND = function(a, b)
	
	--------
	local p, c = 1, 0
	while (a > 0 and b > 0) 
	do
		local ra, rb = (a % 2), (b % 2)
		if (ra + rb > 1) then 
			c = c + p end
			
		------
		a, b, p = ((a - ra) / 2), ((b - rb) / 2), (p * 2)
	end
	
	--------
	return c
end

---------------------------
-- bit.LeftShift

bit.LeftShift = function(x, iBy)
	return (x * 2 ^ iBy)
end

---------------------------
-- bit.RightShift

bit.RightShift = function(x, iBy)
	return (math.floor(x / 2 ^ iBy))
end

---------------------------
-- bit.Next

bit.Next = function(x)
	return (x * 2)
end

---------------------------
-- bit.Next

bit.GetAll = function(x, get)
	local a = {}
	for _, f in pairs(get) do
		if (BitOR(x, f) > 0) then
			table.insert(a, f)
		end
	end
	return table.concat(a, ",")
end

-------------------
BitXOR = bit.XOR
BitOR = bit.OR
BitNOT = bit.NOT
BitAND = bit.AND
BitShift = bit.RightShift
BitLeftShift = bit.LeftShift
BitNext = bit.Next
BitGetAll = bit.GetAll

-------------------
return bit