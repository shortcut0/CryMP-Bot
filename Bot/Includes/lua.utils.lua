--=====================================================
-- CopyRight (c) R 2022-2203
--
-- Random (sometimes) useful utils for lua
--
--=====================================================

-------------------
luautils = {
	version = "1.0",
	author = "shortcut0",
	description = "all kinds of utiliy functions that might come in handy"
}

---------------------------
-- luautils.isfunction

luautils.isfunction = function(hParam)
	return type(hParam) == "function"
end

---------------------------
-- luautils.isString

luautils.isString = function(hParam)
	return type(hParam) == "string"
end

---------------------------
-- luautils.isNumber

luautils.isNumber = function(hParam)
	return type(hParam) == "number"
end

---------------------------
-- luautils.isArray

luautils.isArray = function(hParam)
	return type(hParam) == "table"
end

---------------------------
-- luautils.isNull

luautils.isNull = function(hParam)
	return type(hParam) == "nil"
end

---------------------------
-- luautils.isEntityId

luautils.isEntityId = function(hParam)
	return type(hParam) == "userdata"
end

---------------------------
-- luautils.fileexists

luautils.fileexists = function(sPath)
	-------------
	local hFile = io.open(sPath, "r")
	if (not hFile) then
		return false end
	
	-------------
	hFile:close()
	
	-------------
	return true
end

---------------------------
-- luautils.fileexists

luautils.random = function(min, max, floor)
	-------------
	if (isArray(min)) then
		return min[math.random((max or table.count(min)))]
	end
	
	-------------
	local iRandom
	if (max) then
		iRandom = math.random(min, max)
	else
		iRandom = math.random(0, min)
	end
	
	-------------
	if (floor) then
		iRandom = math.floor(iRandom)
	end
	
	-------------
	return iRandom
end

-------------------
getrandom = luautils.random
isNull = luautils.isNull
isArray = luautils.isArray
isString = luautils.isString
isNumber = luautils.isNumber
isfunction = luautils.isfunction
isEntityId = luautils.isEntityId
fileexists = luautils.fileexists

-------------------
return luautils