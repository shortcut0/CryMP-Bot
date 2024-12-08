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
-- vector.newvec ???

vector.newvec = function(x, y, z)

	local vNew = table.copy(vector)

	vNew.IS_VECTOR = true
	if (vNew.isvector(x)) then
		vNew.x = x.x
		vNew.y = x.y
		vNew.z = x.z
	else
		vNew.x = checkNumber(x, 0)
		vNew.y = checkNumber(y, 0)
		vNew.z = checkNumber(z, 0)
	end

	vNew.expose = function()
		return { vNew.x, vNew.y, vNew.z }
	end

	return vNew
end

---------------------------
-- vector.isvector

vector.isvector = function(v)
	return (isArray(v) and (table.count(v) == 3 or v.IS_VECTOR) and (isNumber(v.x) and isNumber(v.y) and isNumber(v.z)))
end

---------------------------
-- vector.isvalidvector

vector.isvalidvector = function(v)
	return (vector.type(v) ~= "unknown")
end

---------------------------
-- vector.isvector

vector.is2dvector = function(v)
	return (isArray(v) and (table.count(v) == 2 or v.IS_VECTOR) and (isNumber(v.x) and isNumber(v.y)))
end

---------------------------
-- vector.isvector

vector.is1dvector = function(v)
	return (isArray(v) and (table.count(v) == 1 or v.IS_VECTOR) and (isNumber(v.x)))
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
-- vector.tostring

vector.tostring = function(v)
	if (not vector.isvalidvector(v)) then
		return "{}"
	end
	
	local sVector = ""
	if (v.x) then
		sVector = sVector .. (sVector ~= "" and ", " or "") .. "x = " .. (v.x)
	end
	if (v.y) then
		sVector = sVector .. (sVector ~= "" and ", " or "") .. "y = " .. (v.y)
	end
	if (v.z) then
		sVector = sVector .. (sVector ~= "" and ", " or "") .. "z = " .. (v.z)
	end
	
	return "{ " .. sVector .. " }"
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
	local iX = (tonumber(v.x) or 0)
	local iY = (tonumber(v.y) or 0)
	local iZ = (tonumber(v.z) or 0)
	
	local vNew = {
		x = iX,
		y = iY,
		z = iZ
	}
	
	return vNew
end

---------------------------
-- vector.withinfov

vector.withinfov = function(v1, v2, v_camera, i_fov)

	-- dir
	local vDir = vector.dir(v1, v2, true) -- dir to target
	local iDot = vector.dot(vDir, v_camera) -- dot from camera and dir to taregt
	local iHalfFOV = math.cos(math.rad(i_fov / 2))

	return (iDot >= iHalfFOV)
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
-- vector.addInPlace

vector.addInPlace = function(v1, v2)

	------------------
	if (not vector.isvector(v1)) then
		return end
		
	------------------
	if (not vector.isvector(v2)) then
		return end
	
	------------------
	local vNew = vector.new(v1)
	local vAdd = vector.new(v2)
	
	------------------
	vNew.x = vNew.x + vAdd.x
	vNew.y = vNew.y + vAdd.y
	vNew.z = vNew.z + vAdd.z
	
	------------------
	return vNew
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
-- vector.cross

vector.cross = function(v1, v2)

	------------------
	if (not vector.isvector(v1)) then
		return end

	------------------
	if (not vector.isvector(v2)) then
		return end

	------------------
	return {
		x = (v1.y * v2.z - v1.z * v2.y),
		y = (v1.z * v2.x - v1.x * v2.z),
		z = (v1.x * v2.y - v1.y * v2.x)
	}
end

---------------------------
-- vector.dot

vector.dot = function(v1, v2)

	------------------
	if (not vector.isvector(v1)) then
		return end

	------------------
	if (not vector.isvector(v2)) then
		return end

	------------------
	return (v1.x * v2.x + v1.y * v2.y + v1.z * v2.z)
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
-- vector.isnormalized

vector.isnormalized = function(v)

	local iTolerance = 1e-6
	local iLength = vector.length(v)
	local iAbsolute =(math.abs(iLength - 1.0))

	return (iAbsolute < iTolerance)
end

---------------------------
-- vector.normalize

vector.normalize = function(v)

	------------------
	if (not vector.isvector(v)) then
		return v end

	------------------
	if (vecNormalize) then
		return vecNormalize(v)
	end

	local iMag = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
	if (iMag == 0) then
		return vector.new()
	end

	return {
		x = v.x / iMag,
		y = v.y / iMag,
		z = v.z / iMag
	}
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
-- vector.scaleInPlace

vector.scaleInPlace = function(v, iMul, sKey)

	------------------
	if (not vector.isvector(v)) then
		return v end

	------------------
	local n = vector.copy(v)
	if (sKey and vector.iskey(sKey)) then
		n[sKey] = n[sKey] * iMul
	else
		n.x = n.x * iMul
		n.y = n.y * iMul
		n.z = n.z * iMul
	end

	------------------
	return n
end

---------------------------
-- vector.bbox

vector.bbox = function()
	return { min = vector.new(), max = vector.new() }
end

---------------------------
-- vector.bbox_size

vector.bbox_size = function(bbox)
	local size = {}
	local min = (bbox.min or bbox[1])
	local max = (bbox.max or bbox[2])

	size.x = (max.x - min.x)
	size.y = (max.y - min.y)
	size.z = (max.z - min.z)
	return size
end

---------------------------
-- vector.dir

vector.dir = function(v1, v2, bNormalize, iScale)

	-- THIS IS CORRECT !!!
	return (vector.getdir(v2, v1, bNormalize, iScale))
end

---------------------------
-- vector.getdir

vector.getdir = function(v1, v2, bNormalize, iScale)

	------------------
	if (not vector.isvector(v1)) then
		return throw_error("getdir(v1) is no vector") end
		
	------------------
	if (not vector.isvector(v2)) then
		return throw_error("getdir(v2) is no vector") end

	------------------
	-- THIS RETURNS DIR FROM v2 TO v1, NOT the other way around!!!!
	local vDirection = vector.sub(vector.new(v1), vector.new(v2))
	if (bNormalize and not vector.isnull(vDirection)) then
		vDirection = vector.normalize(vDirection) end

	------------------
	if (iScale) then
		vDirection = vector.scale(vDirection, iScale)
	end

	------------------
	return vDirection
end

---------------------------
-- vector.getyawpitch

vector.getyawpitch = function(vDir)

	if (not vector.isvector(vDir)) then
		return
	end

	local iX = vDir.x
	local iY = vDir.y
	local iZ = vDir.z


	local iMag = math.sqrt(iX * iX + iY * iY + iZ * iZ)
	local iYaw = math.atan2(iY, iX)
	local iPitch = math.asin(iZ / iMag)

	-- Convert yaw and pitch from radians to degrees (optional)
	local iYaw_Deg = math.deg(iYaw)
	local iPitch_Deg = math.deg(iPitch)

	return iYaw_Deg, iPitch_Deg
end

---------------------------
-- vector.getang

vector.length = function(v)
	if (vector.is2dvector(v)) then
		return vector.length2d(v)
	elseif (vector.is1dvector(v)) then
		return vector.length1d(v)
	end
	return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end

---------------------------
-- vector.length2d

vector.length2d = function(v)
	return math.sqrt(v.x * v.x + v.y * v.y)
end

---------------------------
-- vector.length1d

vector.length1d = function(v)
	return math.sqrt(v.x * v.x)
end

---------------------------
-- vector.getang

vector.getang = function(v1, v2)

	------------------
	if (not vector.isvector(v1)) then
		return end

	if (not vector.isvector(v2)) then
		return end

	-------------------
	local iX, iY, iZ = v1.x - v2.x, v1.y - v2.y, v1.z - v2.z
	local iDist = math.sqrt(iX * iX + iY * iY + iZ * iZ)

	-------------------
	local vAng = {
		x = math.atan2(iZ, iDist),
		y = 0,
		z = math.atan2(-iX, iY)
	}

	-------------------
	return vAng
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
-- vector.modifyz

vector.modifyz = function(v, new, replace)

	------------------
	if (not vector.isvector(v)) then
		return v end
	
	------------------
	local vNew = vector.new(v)
	local iNew = (vNew.z + new)
	if (replace) then
		iNew = new end
		
	------------------
	vNew.z = iNew
	
	------------------
	return vNew
end

---------------------------
-- vector.modifyx

vector.modifyx = function(v, new, replace)

	------------------
	if (not vector.isvector(v)) then
		return v end
	
	------------------
	local vNew = vector.new(v)
	local iNew = (vNew.x + new)
	if (replace) then
		iNew = new end
		
	------------------
	vNew.x = iNew
	
	------------------
	return vNew
end

---------------------------
-- vector.modifyy

vector.modifyy = function(v, new, replace)

	------------------
	if (not vector.isvector(v)) then
		return v end
	
	------------------
	local vNew = vector.new(v)
	local iNew = (vNew.y + new)
	if (replace) then
		iNew = new end
		
	------------------
	vNew.y = iNew
	
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
		throw_error(".distance(v1) is no vector")
		return 0 end

	------------------
	if (not vector.isvector(v2)) then
		throw_error(".distance(v2) is no vector")
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
-- vector.left

vector.left = function(v)
	return { x = v.y, y = -v.x, z = v.z }
end

---------------------------
-- vector.right

vector.right = function(v)
	return { x = -v.y, y = v.x, z = v.z }
end

---------------------------
-- vector.reverse

vector.reverse = function(v)
	return { x = -v.x, y = -v.y, z = v.z }
end

---------------------------
-- vector.reverse

vector.mid = function(v1, v2)
	local iX = ((v1.x + v2.x) / 2)
	local iY = ((v1.y + v2.y) / 2)
	local iZ = ((v1.z + v2.z) / 2)

	-----
	return { x = iX, y = iY, z = iZ }
end

---------------------------
-- vector.reverse

vector.interpolate = function(v1, v2, i)
	local iX = (v1.x + i * (v2.x - v1.x))
	local iY = (v1.y + i * (v2.y - v1.y))
	local iZ = (v1.z + i * (v2.z - v1.z))

	-----
	return { x = iX, y = iY, z = iZ }
end

---------------------------
-- vector.reverse

vector.between = function(v1, v2, distance)

	-----
	local vDir = vector.getdir(v1, v2, 1, -1)
	local vDirScaled = vector.scaleInPlace(vDir, distance)

	-----
	return vector.addInPlace(v1, vDirScaled)
end

---------------------------
-- vector.rotate_90z

vector.rotaten = function(v, i)

	------------------
	if (not vector.isvector(v)) then
		return v end

	------------------
	VecRotate90_Z(v)
	for _i = 1, (i - 1) do
		--n = VecRotate90_Z(v)
		VecRotate90_Z(v)
	end
	return v
end

---------------------------
-- vector.rotatel

vector.rotatel = function(v)

	------------------
	if (not vector.isvector(v)) then
		return v end

	------------------
	return vector.rotaten(v, 3)
end

---------------------------
-- vector.rotater

vector.rotater = function(v)

	------------------
	if (not vector.isvector(v)) then
		return v end

	------------------
	return vector.rotaten(v, 1)
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
-- vector.check
vector.check = function(v, hDefault)

	------------------
	if (not vector.isvector(v)) then
		return checkVar(hDefault, vector.new()) end

	------------------
	return v
end


---------------------------
Vec3 = vector.make
Ang3 = vector.make
Dir3 = vector.make
checkVec = vector.check


---------------------------
return vector