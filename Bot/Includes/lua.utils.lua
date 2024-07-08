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
-- luautils.checkNumberEx

luautils.checkNumberEx = function(iNumber, hDefault)

	local iCheck = tonumber(iNumber or "")

	-------------
	if (not isNumber(iCheck)) then
		return hDefault end
		
	-------------
	return iCheck
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
-- luautils.checkFuncEx

luautils.checkFuncEx = function(fFunc, hDefault)

	-------------
	if (isNull(fFunc) or not isFunc(fFunc)) then
		return hDefault end

	-------------
	return fFunc
end

---------------------------
-- luautils.checkArray

luautils.checkArray = function(aArray, hDefault)

	-------------
	if (not isArray(aArray)) then
		if (isNull(hDefault)) then
			return { }
		elseif (isArray(hDefault)) then
			return hDefault
		else
			return { hDefault } 
		end
	end

	-------------
	return aArray
end

---------------------------
-- luautils.checkArrayEx

luautils.checkArrayEx = function(aArray, hDefault)

	-------------
	if (not isArray(aArray)) then
		return hDefault
	end

	-------------
	return aArray
end

---------------------------
-- luautils.checkString

luautils.checkString = function(sString, hDefault)

	-------------
	if (not isString(sString)) then
		return hDefault
	end

	-------------
	return sString
end

---------------------------
-- luautils.checkGlobal

luautils.checkGlobal = function(hGlobal, hDefault)

	-------------
	if (isNull(hGlobal)) then
		return hDefault
	end

	-------------
	local bOk, fFunc, sErr, sType, hValue
	if (isString(hGlobal)) then

		local fLoad = (loadstring or load)
		bOk, fFunc = pcall(fLoad, string.format("return %s", checkString(hGlobal)))
		if (not bOk) then
			return hDefault
		end

		bOk, sErr = pcall(fFunc)
		if (not bOk and string.findex(checkString(sErr), "attempt to index global", "attempt to index a nil value")) then
			return hDefault
		end
		
		return sErr
	end

	-------------
	return hDefault

end

---------------------------
-- luautils.traceback

luautils.traceback = function(fLog, aGsub, iSkip)

	local fLogFunc = checkFuncEx(fLog, function(sMsg)
		print(sMsg)
	end)

	-------------
	local sTraceback = debug.traceback()
	if (string.empty(sTraceback)) then
		fLogFunc("<Traceback Failed>")
		return
	end


	local nSkip = checkNum(iSkip, 0)
	for i, sLine in pairs(string.split(sTraceback, "\n")) do
		if (nSkip == 0 or (i > nSkip)) then
			fLogFunc(string.gsubex(sLine, checkArray(aGsub, {}), ""))
		end
	end

end

---------------------------
-- luautils.tracebackex
luautils.tracebackex = function(sMessage, iLevel)
    iLevel = iLevel or 1
    local sTrace = "stack traceback:"
    while (true) do
        local aInfo = debug.getinfo(iLevel, "Sln")
        if (not aInfo) then break end
        sTrace = (sTrace .. "\n\t" .. (aInfo.short_src or "C") .. ":" .. (aInfo.currentline or "?") .. ":")
        if (aInfo.name) then
            sTrace = (sTrace .. " in function '" .. aInfo.name .. "'")
        end
        iLevel = iLevel + 1
    end
    if (sMessage) then
        sTrace = (sTrace .. "\n\t" .. sMessage)
    end
    return sTrace
end

---------------------------
-- luautils.getDummyFunc

luautils.getDummyFunc = function()

	-------------
	return function()
	end

end
---------------------------
-- luautils.repeatargument

luautils.repeatargument = function(hArg, iSteps)

	-------------
	local aArgs = { }
	for i = 1, iSteps do
		aArgs[i] = hArg
	end
	
	-------------
	return luautils.unpack(aArgs)

end
---------------------------
-- luautils.unpack

luautils.unpack = function(t, i, j)

	-------------
    local i = (i or 1)
    local j = (j or table.count(t))
    if (j < i) then
        return
    end

	-------------
    local function unpackHelper(i, j)
        if (i <= j) then
            return t[i], unpackHelper((i + 1), j)
        end
    end

	-------------
    return unpackHelper(i, j)
end

---------------------------
-- luautils.switch

luautils.switch = function(value)
    return function(cases)
        local case = cases[value]
		local hDef = cases.default
        if (case) then
            if (isFunc(case)) then
                return case()
            else
                return case
            end
        elseif (hDef) then
            if (isFunc(hDef)) then
                return hDef()
            else
                return hDef
            end
        else
            error("No case found for value: " .. tostring(value))
        end
    end
end

---------------------------
-- luautils.increase

luautils.INCREASE = nil
luautils.INCREASE_ADD = nil
luautils.INCREASE_MULT = nil
luautils.INCREASE_DIV = nil

luautils.increase = function(start, add)

	local add = (add or 1)

	local bEnd = string.matchex(start, "end")
	if (start and not bEnd) then
		luautils.INCREASE = start
		luautils.INCREASE_ADD = nil
		luautils.INCREASE_MULT = nil
		luautils.INCREASE_DIV = nil

		if (string.match(add, "^%*")) then
			luautils.INCREASE_MULT = string.match(add, "(%d+)")
		elseif (string.matchex(add, "^\\", "^/")) then
			luautils.INCREASE_DIV = string.match(add, "(%d+)")
		else
			luautils.INCREASE_ADD = add
		end

		return start
	end

	if (not luautils.INCREASE) then
		return
	end

	if (luautils.INCREASE_ADD) then
		luautils.INCREASE = (luautils.INCREASE + luautils.INCREASE_ADD)
	elseif (luautils.INCREASE_MULT) then
		luautils.INCREASE = (luautils.INCREASE * luautils.INCREASE_MULT)
	elseif (luautils.INCREASE_DIV) then
		luautils.INCREASE = (luautils.INCREASE / luautils.INCREASE_DIV)
	end

	local r = luautils.INCREASE
	if (bEnd) then
		luautils.INCREASE = nil
		luautils.INCREASE_ADD = nil
		luautils.INCREASE_MULT = nil
		luautils.INCREASE_DIV = nil
	end
	return r
end

-------------------

local function makeAny(f)
	return function(...)
		local a = { ... }
		if (table.count(a) < 1) then return end
		local bOk
		for i, hParam in pairs(a) do
			bOk = bOk or f(hParam)
		end
		return bOk
	end
end

local function makeAll(f)
	return function(...)
		local a = { ... }
		if (table.count(a) < 1) then return end
		local bOk = true
		for i, hParam in pairs(a) do
			bOk = bOk and f(hParam)
		end
		return bOk
	end
end

-------------------

inc = luautils.increase
unpack = (unpack or luautils.unpack)
getrandom = luautils.random
isNull = luautils.isNull
isDead = luautils.isDead
isArray = luautils.isArray
isBoolean = luautils.isBoolean
isBool = luautils.isBoolean
isString = luautils.isString
isNumber = luautils.isNumber
isNumberAll = makeAll(isNumber)
isNumberAny = makeAny(isNumber)
isFunction = luautils.isFunction
isFunc = luautils.isFunction
isEntityId = luautils.isEntityId
isUserdata = luautils.isEntityId
fileexists = luautils.fileexists
checkNumber = luautils.checkNumber
checkNumberEx = luautils.checkNumberEx
checkNum = luautils.checkNumber
checkNumEx = luautils.checkNumberEx
checkVar = luautils.checkVar
checkFunc = luautils.checkFunc
checkFuncEx = luautils.checkFuncEx
checkArray = luautils.checkArray
checkGlobal = luautils.checkGlobal
checkString = luautils.checkString
compNumber = luautils.compNumber
GetDummyFunc = luautils.getDummyFunc
doTraceback = luautils.traceback
repeatArg = luautils.repeatargument
switch = luautils.switch
tracebackEx = luautils.tracebackex

-------------------
return luautils