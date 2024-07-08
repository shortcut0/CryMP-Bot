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
-- luautils.isFunction

luautils.isFunction = function(hParam)
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
-- luautils.isBoolean

luautils.isBoolean = function(hParam)
	return type(hParam) == "bool"
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
-- luautils.isDead

luautils.isDead = function(hParam)
	return (isNumber(hParam) and hParam == 0xDEAD)
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
		if (max and isFunction(max) and table.count(min) > 1) then
			for i, hVal in pairs(table.shuffle(min)) do
				if (max(hVal) == true) then
					return hVal
				end
			end
		else
			return min[math.random((max or table.count(min)))] end
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

---------------------------
-- luautils.checkNumber

luautils.checkNumber = function(iNumber, iDefault)

	-------------
	if (not isNumber(iNumber)) then
		return iDefault end
	-------------
	return iNumber
end

---------------------------
-- luautils.compNumber

luautils.compNumber = function(iNumber, iGtr)

	-------------
	if (not isNumber(iNumber)) then
		return false end

	-------------
	if (not isNumber(iGtr)) then
		return false end
		
	-------------
	return (iNumber >= iGtr)
end

---------------------------
-- luautils.checkVar

luautils.checkVar = function(sVar, hDefault)

	-------------
	if (isNull(sVar)) then
		return hDefault end
		
	-------------
	return sVar
end

---------------------------
-- luautils.checkFunc

luautils.checkFunc = function(fFunc, hDefault, ...)

	-------------
	if (isNull(fFunc) or not isFunc(fFunc)) then
		return hDefault end
		
	-------------
	local hReturn = fFunc(...)
	if (isNull(hReturn)) then
		return hDefault end
		
	-------------
	return hReturn
end

---------------------------
-- luautils.checkArray

luautils.checkArray = function(aArray, hDefault)

	-------------
	if (not isArray(aArray)) then
		if (isArray(hDefault)) then
			return hDefault else
			return { hDefault } end 
	end
		
	-------------
	return aArray
end

---------------------------
-- luautils.getDummyFunc

luautils.getDummyFunc = function()

	-------------
	return function()
	end

end

-------------------
getrandom = luautils.random
isNull = luautils.isNull
isDead = luautils.isDead
isArray = luautils.isArray
isBoolean = luautils.isBoolean
isBool = luautils.isBoolean
isString = luautils.isString
isNumber = luautils.isNumber
isFunction = luautils.isFunction
isFunc = luautils.isFunction
isEntityId = luautils.isEntityId
fileexists = luautils.fileexists
checkNumber = luautils.checkNumber
checkNum = luautils.checkNumber
checkVar = luautils.checkVar
checkFunc = luautils.checkFunc
checkArray = luautils.checkArray
compNumber = luautils.compNumber
GetDummyFunc = luautils.getDummyFunc

-------------------
return luautils