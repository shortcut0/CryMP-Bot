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
-- luautils.throw_error

luautils.throw_error = function(sMessage)


	local sMsg = string.format("Error Thrown (%s)\n\t%s", tostring(sMessage), tostring(tracebackEx()))
	local fMsg = (luautils.ErrorMessageHandler)
	if (fMsg) then
		--fMsg(sMsg)
	end

	error(sMsg)

	--local i = 0
	--while ((_G["nothing_" .. i]) ~= nil) do
	--	i = i + 1
	--end
	--_G["nothing_" .. i]()
end

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
	elseif (min) then
		iRandom = math.random(0, min)
	else
		return 0
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
-- checkArray(nil, { "x" }) 	-> { "x"  }
-- checkArray(nil, "x") 		-> { "x"  }
-- checkArray(nil, nil) 		-> { nil  }

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
---
-- does not force hDefault to be an
-- array and instead returns it as-is

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
-- checkGlobal("_G", x)				-> _G
-- checkGlobal("MY_GLOBAL", x)		-> gMY_GLOBAL (if null, returns x)
-- checkGlobal(MY_GLOBAL, x)		-> gMY_GLOBAL (if null, returns x)

luautils.checkGlobal = function(hGlobal, hDefault, fCheck, pCheck)

	-------------
	if (isNull(hGlobal)) then
		return hDefault
	end

	-------------
	local bOk, fFunc, sErr, sType, hValue
	if (isString(hGlobal)) then

		local fLoad = (loadstring or load)
		local sFunc = string.format("return %s", checkString(hGlobal))

		-- load string
		bOk, fFunc = pcall(fLoad, sFunc)
		if (not bOk) then
			return hDefault
		end

		-- execute string
		bOk, sErr = pcall(fFunc)
		if (not bOk and string.findex(checkString(sErr), "attempt to index global", "attempt to index a nil value")) then
			return hDefault
		end

		-- it's undefined
		if (sErr == nil) then
			return hDefault
		end

		-- global value
		if (isFunc(fCheck)) then
			return fCheck(sErr, checkVar(pCheck, hDefault))
		end
		return sErr
	end

	-------------
	return hDefault

end

---------------------------
-- luautils.traceback
--
-- Args
--  1. MyLogFunction <if nil, PRINT is used>,
--  2. sCleanPattern <the pattern to clean the line from (eg: "\t" to remove tabulators)>,
--  3. iSkipLines <the amount of lines to skip from the traceback>)

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
--
-- Custom traceback, similar to build-in one
-- Args
--  1. sMessage <a message to append to the final traceback ("L:MESSAGE" to append it to the end of each line)>

luautils.tracebackex = function(sMessage, iLevel, sPrefix)

	local bAppendLine = (string.matchex(sMessage, "^L:(.*)$") ~= nil)
    local iLevel = checkNumber(iLevel, 1)
    local sTrace = (sPrefix or "stack traceback:")
    while (true) do
        local aInfo = debug.getinfo(iLevel, "Sln")
        if (not aInfo) then break end
        sTrace = (sTrace .. "\n\t" .. (aInfo.short_src or "C") .. ":" .. (aInfo.currentline or "?") .. ":")
        if (aInfo.name) then
            sTrace = (sTrace .. " in function '" .. aInfo.name .. "'") .. (bAppendLine and sMessage or "")
        end
        iLevel = iLevel + 1
    end
    if (sMessage and not bAppendLine) then
        sTrace = (sTrace .. "\n\t" .. sMessage)
    end
    return sTrace
end

---------------------------
-- luautils.getDummyFunc

luautils.getDummyFunc = function(throw)

	-------------
	return function()
		if (throw) then
			throw_error("dummy function called!!")
		end
	end

end

---------------------------
-- luautils.getDummyFunc

luautils.getErrorDummy = function()

	-------------
	return function(...)
		throw_error(string.format(
				"Dummy Called (Arguments: %s)",
				table.concatEx({ ... }, ", ", table.CONCAT_PREDICATE_TYPES)
		))
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
-- luautils.callAndExecute
-- calls a function and executes all tasks in 'calls'
-- Args
--  1. f, the function to call (eg: callAndExecute(timernew), NOT callAndExecute(timernew()) UNLESS that itself returns a function)
--  2. params, the parameters to pass to 'f'
--  3. calls, the array containing all the tasks where index_1 is the name of the function and index_2+

luautils.callAndExecute = function(f, params, calls)

	local aRet = { f(unpack(params)) }
	local hObj = aRet[1]

	if (isArray(hObj)) then
		if (table.count(calls) > 0) then
			for i, aCall in pairs(calls) do
				--print(table.tostring(aCall))
				--print("call " .. tostring(aCall[1]) .. " w: " .. table.tostring({luautils.unpack(aCall, 2)}))
				local bOk, sErr = pcall(hObj[aCall[1]], luautils.unpack(aCall, 2))
				if (not bOk) then
					error(sErr)
				end
			end
		end
	end

	return unpack(aRet)
end

------------------------------

luautils.INCREASE = nil
luautils.INCREASE_ADD = nil
luautils.INCREASE_MULT = nil
luautils.INCREASE_DIV = nil

---------------------------
-- luautils.increase

luautils.EndInc = function(bKeepInc)
	luautils.INCREASE_ADD = nil
	luautils.INCREASE_MULT = nil
	luautils.INCREASE_DIV = nil
	luautils.INCREASE_SUB = nil
	if (not bKeepInc) then
		luautils.INCREASE = nil end
end

---------------------------
-- luautils.increase

luautils.StepInc = function()

	-- Add
	if (luautils.INCREASE_ADD) then
		luautils.INCREASE = (luautils.INCREASE + luautils.INCREASE_ADD)

	-- Mult
	elseif (luautils.INCREASE_MULT) then
		luautils.INCREASE = (luautils.INCREASE * luautils.INCREASE_MULT)

	-- Div
	elseif (luautils.INCREASE_DIV) then
		luautils.INCREASE = (luautils.INCREASE / luautils.INCREASE_DIV)

	-- Sub
	elseif (luautils.INCREASE_SUB) then
		luautils.INCREASE = (luautils.INCREASE - luautils.INCREASE_SUB)

	end
end

---------------------------
-- luautils.increase

luautils.SetupInc = function(i)

	--------
	if (string.match(i, "^%*")) then
		luautils.INCREASE_MULT = string.match(i, "(%d+)")
		print("mul " .. i)

	elseif (string.matchex(i, "^\\", "^/")) then
		luautils.INCREASE_DIV = string.match(i, "(%d+)")
		print("div " .. i)

	elseif (string.matchex(i, "^%-")) then
		luautils.INCREASE_SUB = string.match(i, "(%d+)")
		print("sub " .. i)

	else
		luautils.INCREASE_ADD = i
		print("add " .. i)
	end
end

---------------------------
-- luautils.increase
--
-- Args
--  1. Initial value (or 0)
--  2. Next value ( can be "/10" to DIVIDE, "*10" to MULTIPLY, "+10" to INCREMENT, or "-10" to DECREMENT - the Initital value )
-- Examples:
--  v = inc(1000, "+10") -> 1000 (No incrementing is done on the initial call)
--  w = inc(nil, "+15")  -> 1015 (Now +15)
--  x = inc()			 -> 1030 (+15)
--  y = inc()			 -> 1045 (+15)
--  z = inc("end")		 -> 1060 (+15 and stop inc())
--  	^ OR incEnd()	 -> 1060 (+15 and stop inc())

luautils.increase = function(start, add)

	local iAdd = checkVar(add, 1)
	local bEnd = string.matchex(start, "end")
	if (start and not bEnd) then

		luautils.INCREASE = start
		luautils.EndInc(true)
		luautils.SetupInc(iAdd)


		return start
	end

	if (not luautils.INCREASE) then
		return
	end

	if (add) then
		luautils.EndInc(true)
		luautils.SetupInc(iAdd) -- dynamic update of the steps
	end

	luautils.StepInc()

	local r = luautils.INCREASE
	if (bEnd) then
		luautils.EndInc()
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

callAnd = luautils.callAndExecute

inc = luautils.increase
incEnd = function() return inc("end")  end
unpack = (unpack or luautils.unpack)
getrandom = luautils.random
isNull = luautils.isNull
isNullAny = makeAny(isNull)
isNullAll = makeAll(isNull)
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
GetErrorDummy = luautils.getErrorDummy
repeatArg = luautils.repeatargument
switch = luautils.switch
traceback = luautils.traceback
tracebackEx = luautils.tracebackex
throw_error = luautils.throw_error

-------------------
return luautils