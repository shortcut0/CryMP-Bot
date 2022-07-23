--=====================================================
-- CopyRight (c) R 2022-2203
--
-- Random (sometimes) useful vector utils for lua
--
--=====================================================

-------------------
vector = {
	version = "1.0",
	author = "shortcut0",
	description = "all kinds of vector utiliy functions that might come in handy",
	requires = "lua.utils.lua;table.utils.lua"
}

-------------------
vectors = {
	down = { x = 0, y = 0, z = -1 },
	down_m = { x = 0, y = 0, z = -0.75 },
	down_s = { x = 0, y = 0, z = -0.95 },
	up = { x = 0, y = 0, z = 1 },
}

---------------------------
-- vector.isvector

vector.isvector = function(v)
	return (isArray(v) and table.count(v) == 3 and (isNumber(v.x) and isNumber(v.y) and isNumber(v.z)))
end

---------------------------
-- vector.isvector

vector.is2dvector = function(v)
	return (isArray(v) and table.count(v) == 2 and (isNumber(v.x) and isNumber(v.y)))
end

---------------------------
-- vector.isvector

vector.is1dvector = function(v)
	return (isArray(v) and table.count(v) == 1 and (isNumber(v.x)))
end

---------------------------
-- vector.iskey

vector.iskey = function(sKey)

	------------------
	local sKey = string.lower(sKey or "")
	return (sKey == "x" or sKey == "y" or sKey == "z")
end

---------------------------
-- vector.copy

vector.copy = function(v)
	return table.copy(v)
end

---------------------------
-- vector.new

vector.new = function(v)
	if (v) then
		return table.copy(v)
	else
		return { x = 0, y = 0, z = 0 }
	end
end

---------------------------
-- vector.make

vector.make = function(iX, iY, iZ, vReturn)
	
	local vNew = {
		x = checkNumber(iX, 0),
		y = checkNumber(iY, 0),
		z = checkNumber(iZ, 0)
	}
	
	if (vReturn) then
		vReturn = vNew end
	
	return vNew
end

---------------------------
-- vector.amake

vector.amake = function(a, vReturn)
	
	if (not isArray(a)) then
		return a end
	
	local vNew = {
		x = checkNumber(a[1], 0),
		y = checkNumber(a[2], 0),
		z = checkNumber(a[3], 0)
	}
	
	if (vReturn) then
		vReturn = vNew end
	
	return vNew
end

---------------------------
-- vector.type

vector.type = function(v)

	------------------
	local sType = "unknown"
	local iSize = table.count(v)
	
	------------------
	if (vector.isvector(v)) then
		sType = "3D"
	elseif (vector.is2dvector(v)) then
		sType = "2D"
	elseif (vector.is1dvector(v)) then
		sType = "1D"
	end
	
	------------------
	return sType
end

---------------------------
-- vector.isnull

vector.isnull = function(v)

	------------------
	if (not vector.isvector(v)) then
		return true end

	------------------
	return (v.x == 0 and v.y == 0 and v.z == 0)
end

---------------------------
-- vector.validate

vector.validate = function(v)

	------------------
	if (vector.isvector(v)) then
		return v end

	------------------
	local iX = tonumber(v.x) or 0
	local iY = tonumber(v.y) or 0
	local iZ = tonumber(v.z) or 0
	
	local vNew = {
		x = iX,
		y = iY,
		z = iZ
	}
	
	return vNew
end

---------------------------
-- vector.add

vector.add = function(v1, v2)

	------------------
	if (not vector.isvector(v1)) then
		return end
		
	------------------
	if (not vector.isvector(v2)) then
		return end
	
	------------------
	v1.x = v1.x + v2.x
	v1.y = v1.y + v2.y
	v1.z = v1.z + v2.z
	
	------------------
	return v1
end

---------------------------
-- vector.addN

vector.addN = function(v, i, sKey)

	------------------
	if (not vector.isvector(v)) then
		return end

	------------------
	if (not isNumber(i)) then
		return v end
	
	------------------
	local vNew = vector.new(v)
	if (vector.iskey(sKey)) then
		vNew[sKey] = vNew[sKey] + i
	else
		vNew.x = vNew.x + i
		vNew.y = vNew.y + i
		vNew.z = vNew.z + i
	end
	
	------------------
	return vNew
end

---------------------------
-- vector.sub

vector.sub = function(v1, v2)

	------------------
	if (not vector.isvector(v1)) then
		return end
		
	------------------
	if (not vector.isvector(v2)) then
		return end
	
	------------------
	v1.x = v1.x - v2.x
	v1.y = v1.y - v2.y
	v1.z = v1.z - v2.z
	
	------------------
	return v1
end

---------------------------
-- vector.compare

vector.compare = function(v1, v2)

	------------------
	if (not vector.isvector(v1)) then
		return end
		
	------------------
	if (not vector.isvector(v2)) then
		return end
	
	------------------
	return (v1.x == v2.x and v1.y == v2.y and v1.z == v2.z)
end

---------------------------
-- vector.normalize

vector.normalize = function(v)

	------------------
	if (not vector.isvector(v)) then
		return v end
	
	------------------
	return vecNormalize(v)
end

---------------------------
-- vector.scale

vector.scale = function(v, iMul, sKey)

	------------------
	if (not vector.isvector(v)) then
		return v end
	
	------------------
	if (sKey and vector.iskey(sKey)) then
		v[sKey] = v[sKey] * iMul
	else
		v.x = v.x * iMul
		v.y = v.y * iMul
		v.z = v.z * iMul
	end
	
	------------------
	return v
end

---------------------------
-- vector.getdir

vector.getdir = function(v1, v2, bNormalize)

	------------------
	if (not vector.isvector(v1)) then
		return v1 end
		
	------------------
	if (not vector.isvector(v2)) then
		return v1 end
	
	------------------
	local vDirection = vector.sub(vector.new(v1), vector.new(v2))
	if (bNormalize) then
		vDirection = vector.normalize(vDirection) end
	
	------------------
	return vDirection
end

---------------------------
-- vector.modify

vector.modify = function(v1, key, new, add)

	------------------
	if (not vector.isvector(v1)) then
		return v1 end

	------------------
	if (not vector.iskey(key)) then
		return v1 end
	
	------------------
	local vNew = vector.new(v1)
	local iNew = new
	if (add) then
		iNew = iNew + vNew[key] end
		
	------------------
	vNew[key] = iNew
	
	------------------
	return vNew
end

---------------------------
-- vector.modifyInPlace

vector.modifyInPlace = function(v1, key, new, add)

	------------------
	if (not vector.isvector(v1)) then
		return v1 end

	------------------
	if (not vector.iskey(key)) then
		return v1 end
	
	------------------
	local iNew = new
	if (add) then
		iNew = iNew + v1[key] end
	
	------------------
	v1[key] = iNew
	
	------------------
	return v1
end

---------------------------
-- vector.distance

vector.distance = function(v1, v2)

	------------------
	if (not vector.isvector(v1)) then
		return 0 end

	------------------
	if (not vector.isvector(v2)) then
		return 0 end
	
	------------------
	local iX = (v1.x - v2.x)
	local iY = (v1.y - v2.y)
	local iZ = (v1.z - v2.z)
	
	------------------
	return math.sqrt(iX * iX + iY * iY + iZ * iZ)
end

---------------------------
-- vector.distance2d

vector.distance2d = function(v1, v2)

	------------------
	if (not vector.isvector(v1)) then
		return 0 end

	------------------
	if (not vector.isvector(v2)) then
		return 0 end
	
	------------------
	local iX = (v1.x - v2.x)
	local iY = (v1.y - v2.y)
	
	------------------
	return math.sqrt(iX * iX + iY * iY)
end

---------------------------
-- vector.rotate_90z 

vector.rotate_90z = function(v)

	------------------
	if (not vector.isvector(v)) then
		return v end

	------------------
	return VecRotate90_Z(v)
end

---------------------------
-- vector.rotate_minus90z

vector.rotate_minus90z = function(v)

	------------------
	if (not vector.isvector(v)) then
		return v end

	------------------
	return VecRotateMinus90_Z(v)
end


---------------------------
return vector