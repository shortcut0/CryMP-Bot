--=====================================================
-- CopyRight (c) R 2022-2203
--
-- Random (sometimes) useful table utils for lua
--
--=====================================================

-------------------
arrayutils = {
	version = "0.3r",
	author = "shortcut0",
	description = "all kinds of utiliy functions that might come in handy"
}

---------------------------

table.__NO__RECURSION__ = {}

---------------------------
-- table.lookupName (finish this)

table.lookupName = function(t, val)

	local fLoad = (load or loadstring)

	if (not string.find(val, "([%.:]")) then
		return _G[val] end

	-- local idVar = "_G"
	-- for sAddress in string.gmatch(val, "([^.:]*)") do
		-- if (fLoad("return " .. idVar .. " == nil")) then
			-- return idVar = idVar .. "." .. sAddress 
		-- end 
	-- end
	return
end

---------------------------
-- table.keep

table.keep = function(t, i_keep)
	local aArray = {}
	local i_count = 0
	for i, v in pairs(t) do
		i_count = i_count + 1
		if (i_count <= i_keep) then
			aArray[i] = v
		else
			break
		end
	end
	return aArray
end

---------------------------
-- table.ikeep

table.ikeep = function(t, i_keep)
	local aArray = {}
	local i_count = 0
	for i, v in pairs(t) do
		i_count = i_count + 1
		if (i_count <= i_keep) then
			table.insert(aArray, v)
		else
			break
		end
	end
	--t = aArray
	return aArray
end

---------------------------
-- table.getall

table.getall = function(t, sKey)
	
	local sAll = ""
	if (sKey) then
		for i, v in pairs(t) do
			sAll = sAll .. v[sKey]
		end
	else
		for i, v in pairs(t) do
			sAll = sAll .. v
		end
	end
	return sAll
	
end

---------------------------
-- table.insertFirst

table.insertFirst = function(t, add)
	local tNew = { add }
	for i, v in pairs(t) do
		table.insert(tNew, v)
	end
	return tNew
end

---------------------------
-- table.lookup

table.lookup = function(t, val)
	for k, v in pairs(t) do
		if (v == val) then
			return k end end
	return
end

---------------------------
-- table.lookupI

table.lookupI = function(t, val, index)
	for k, v in pairs(t) do
		if (v[index] == val) then
			return k end end
	return
end

---------------------------
-- table.lookupRec

table.lookupRec = function(t, val, o)
	for k, v in pairs(t) do
		if (v == val) then
			return k 
		else
			if (table.isarray(v) and (o ~= v and o ~= _G)) then
				local t = table.lookupRec(v, val, t)
				if (t) then
					return t end
			end
		end 
	end
	return
end

---------------------------
-- table.lookupk

table.lookupk = function(t, key)
	for k, v in pairs(t) do
		if (key == k) then
			return v end end

	return
end

---------------------------
-- table.contains

table.contains = function(t, val)
	return (table.lookup(t, val) ~= nil)
end

---------------------------
-- table.shallowClone

table.shallowClone = function(t)
	
	local aResult = {}
	for k, v in pairs(t or{}) do
		aResult[k] = v end

	return aResult
end

---------------------------
-- table.copy

table.copy = function(t)
	return table.shallowClone(t)
end

---------------------------
-- table.deepClone

table.deepClone = function(t)
	local aResult = {}
	for k, v in pairs(t) do
		if table.isarray(v) then
			aResult[k] = table.deepClone(v)
		else
			aResult[k] = v
		end
	end
	
	return aResult
end

---------------------------
-- table.deepCopy

table.deepCopy = function(t)
	return table.deepClone(t)
end

---------------------------
-- table.shallowMerge

table.shallowMerge = function(a, b, bOverwrite)
	
	local n = table.copy(a)
	for i, v in pairs(b) do
		if (bOverwrite) then
			n[i] = v
		elseif (n[i] == nil) then
			n[i] = v
		end
	end
	
	return n
end

---------------------------
-- table.shallowMerge

table.shallowMergeInsert = function(a, b, fPred)
	
	local n = table.copy(a)
	for i, v in pairs(b) do
		if (fPred == nil or (fPred(v) == true)) then
			table.insert(n, v)
		end
	end
	
	return n
end

---------------------------
-- table.deepMerge

table.deepMerge = function(a, b, bOverwrite)

	if (not table.isarray(a)) then
		return (table.isarray(b) and b or {})
	elseif (not table.isarray(b)) then
		return (table.isarray(a) and a or {})
	end

	local n = table.copy(a)
	for i, v in pairs(b) do
		if (bOverwrite) then
			if (table.isarray(v)) then
				n[i] = table.deepMerge(n[i], v)
			else
				n[i] = v
			end
		else
			if (table.isarray(v)) then
				if (n[i] == nil) then
					n[i] = v
				else
					n[i] = table.deepMerge(n[i], v)
				end
			elseif (n[i] == nil or (bOverwrite and n[i] ~= v)) then
				n[i] = v
			end
		end
	end
	
	return n
end

---------------------------
-- table.merge

table.merge = function(a, b, bOverwrite)
	return table.shallowMerge(a, b, bOverwrite)
end

---------------------------
-- table.mergeI

table.mergeI = function(a, b, fPred)
	return table.shallowMergeInsert(a, b, fPred)
end

---------------------------
-- table.isarray

table.isarray = function(t)
	return (type(t) == "table")
end

---------------------------
-- table.getmem

table.getmem = function(a, mem)
	local aArray = {}
	for k, v in pairs(a) do
		if (not isNull(a[mem])) then
			aArray[k] = v end
	end
	return aArray
end

---------------------------
-- table.igetmem

table.igetmem = function(a, mem)
	local aArray = {}
	for k, v in pairs(a) do
		if (not isNull(a[mem])) then
			table.insert(aArray, v) end
	end
	return aArray
end

---------------------------
-- table.select

table.select = function(t, pred)
	local aResult = {}
	for k, v in pairs(t) do
		if (pred(v)) then
			aResult[k] = v end
	end
	return aResult
end

---------------------------
-- table.iselect

table.iselect = function(t, pred)
	local aResult = {}
	for _, v in ipairs(t) do
		if (pred(v)) then
			table.insert(aResult, v) end
	end
	return aResult
end

---------------------------
-- table.one

table.one = function(t, pred)
	for _, v in pairs(t) do
		if (pred == nil or pred(v)) then
			return v end end
end

---------------------------
-- table.first

table.first = table.one

---------------------------
-- table.last

table.last = function(t, pred)

	local i = table.count(t)
	local c = 0
	for _, v in pairs(t) do
		c = c + 1
		if ((c >= i and pred == nil) or (isFunc(pred) and pred(v, c))) then
			return v end end
end

---------------------------
-- table.count

table.count = function(t, pred)

	if (not table.isarray(t)) then
		return 0
	end

	local iCount = 0
	for _, v in pairs(t) do
		if (pred == nil or pred(v)) then
			iCount = iCount + 1
		end
	end
	return iCount
end

---------------------------
-- table.getsize

table.getsize = table.count
table.size = table.count

---------------------------
-- table.countTypes

table.countTypes = function(t, bReturnCount)

	------------
	local sTypes = "%d Arrays, %d Floats, %d Strings, %d Booleans, %d Functions, %d Other Entires"
	if (not table.isarray(t)) then
		if (bReturnCount) then
			return 0, 0, 0, 0, 0, 0 end
			
		return string.format(sTypes, 0, 0, 0, 0, 0, 0)
	end

	------------
	local iArrays = 0
	local iFloats = 0
	local iStrings = 0
	local iBooleans = 0
	local iFunctions = 0
	local iOtherEntires = 0
	
	------------
	for _, v in pairs(t) do
		
		if (isArray(v)) then
			local aRet = { table.countTypes(v, true) }
			iArrays = iArrays + aRet[1] + 1
			iFloats = iFloats + aRet[2]
			iStrings = iStrings + aRet[3]
			iBooleans = iBooleans + aRet[4]
			iFunctions = iFunctions + aRet[5]
			iOtherEntires = iOtherEntires + aRet[6]
			
		elseif (isNumber(v)) then
			iFloats = iFloats + 1 elseif (isString(v)) then
			iStrings = iStrings + 1 elseif (isBoolean(v)) then
			iBooleans = iBooleans + 1 elseif (isFunction(v)) then
			iFunctions = iFunctions + 1  else
			iOtherEntires = iOtherEntires + 1
		end
	end
	
	------------
	if (bReturnCount) then
		return iArrays, iFloats, iStrings, iBooleans, iFunctions, iOtherEntires end
	
	------------
	return string.format(sTypes, iArrays, iFloats, iStrings, iBooleans, iFunctions, iOtherEntires)
end

---------------------------
-- table.countRec

table.countRec = function(t, pred, iLevels, iLevel)

	if (not table.isarray(t)) then
		return 0
	end
	
	local iLevel = checkNumber(iLevel, 0)
	
	local bLevelOk = true
	if (isNumber(iLevels)) then
		bLevelOk = iLevel < iLevels end

	local iCount = 0
	for _, v in pairs(t) do
		if (pred == nil or pred(v)) then
			if (table.isarray(v) and bLevelOk) then
				iCount = iCount + table.countRec(v, pred, iLevels, (iLevel + 1))
			else
				iCount = iCount + 1
			end
		end
	end
	return iCount
end

---------------------------
-- table.removeWithPredicate

table.removeWithPredicate = function(t, pred)
	local k, v
	while true do
		k, v = next(t, k)
		if k == nil then
			break
		end
		if (pred(v)) then
			t[k] = nil
		end
	end
end

---------------------------
-- table.removeValue

table.removeValue = function(t, val)
	for k, v in pairs(t) do
		if (v == val) then
			table.remove(t, k)
			return
		end
	end
end

---------------------------
-- table.popFirst

table.popFirst = function(t)
	local v = t[1]
	table.remove(t, 1)
	
	return v
end

---------------------------
-- table.popLast

table.popLast = function(t)
	local v = t[#t]
	table.remove(t, #t)

	return v
end

---------------------------
-- table.empty

table.empty = function(t)
	return (table.count(t) == 0)
end

---------------------------
-- table.getmax

table.getmax = function(t, sKey)
	local iMax
	for i, v in pairs(t) do
		local iNumber = tonumber(v)
		if (isArray(v) and v[sKey]) then
			iNumber = checkNumber(tonumber(v[sKey]), 0) end
			
		if (isNull(iMax) or (checkNumber(iNumber, 0) > iMax)) then
			iMax = iNumber end
	end
	 
	return iMax
end

---------------------------
-- table.findp

table.findp = function(t, hPartial, bPrint)
	local c = 0
	local aArray = {}
	for i, v in pairs(t) do
		c = c + 1
		if (string.find(i, hPartial)) then
			table.insert(aArray, i)
			if (bPrint) then
				print(i)
			end
		end
	end
	 
	return aArray
end

---------------------------
-- table.findp

table.findp_rec = function(t, hPartial, bPrint, bStringFmt, sName, sTab, bRec, sStack)

	sName = sName or ""
	sTab = sTab or ""
	sStack = sStack or table.getorigin(t)
	local sArray = string.gsub(tostring(t), "^table: ", "")
	if (bRec == nil) then
		table.__NO__RECURSION__ = {}
	elseif (table.__NO__RECURSION__[sArray] ~= nil) then
		return
	else
		table.__NO__RECURSION__[sArray] = 1
	end

	local aArray = {}
	local sString = sName
	for i, v in pairs(t) do


		if (isArray(v)) then
			local r = (table.findp_rec(v, hPartial, bPrint, bStringFmt, nil, sTab.."   ", true, sStack .. "."..i))
			if (not table.empty(r) or (bStringFmt and not string.empty(r))) then
				--table.insert(aArray, r)
				aArray[i] = r
				if (bStringFmt and string.find(r, hPartial)) then
					sString = sString .. sTab .. " -> " .. i .. " = { \n" .. r .. "\n" .. sTab .. "},\n"
				end
			elseif (string.find(i, hPartial)) then
				--table.insert(aArray, {})
				aArray[i] = {}
				sString = sString .. string.format("%-75s %12s[stack:%s]\n",  sTab .. " > " .. i, "(" .. type(v) .. ")", sStack)
			end
		elseif (string.find(i, hPartial)) then
			--table.insert(aArray, i)
			aArray[i] = v
			if (bStringFmt) then
				sString = sString .. string.format("%-75s %12s[stack:%s]\n",  sTab .. " > " .. i, "(" .. type(v) .. ")", sStack)
			end
			if (bPrint) then
				print(i)
			end
		end
	end

	if (bRec == nil) then
		table.__NO__RECURSION__ = {}
	end

	if (bStringFmt) then
		return sString
	end
	return aArray
end

---------------------------
-- table.getorigin_fromstring (MOVE TO UTILS LIBRARY?? HAS NOTHING TO DO WITH ARRAYS..)
-- "_G" -> returns global _G array
-- "_G.math" -> returns global math array
-- "math" -> returns global math array
-- "math.mod" -> returns global math.mod function

table.getorigin_fromstring = function(sObj)

	local hObj
	if (not string.find(sObj, "%.")) then
		return _G[sObj]
	end

	local aArray = {}
	for sPart in string.gmatch(sObj, "[^.]*") do
		if (string.len(sPart) > 0) then
			table.insert(aArray, sPart)
		end
	end

	hObj = ("return _G." .. table.concat(aArray, "."))

	local fLoad = (load or loadstring)
	return (fLoad(hObj)())
end

---------------------------
-- table.getorigin (MOVE TO UTILS LIBRARY?? NOT EXCLUSIVE TO ARRAYS ANYMORE..)
-- get the origin location of a variable
-- can be file, userdata, array or function. strings and numbers are NOT supported

table.getorigin = function(t, bFullStack, sOrigin, aCurrent, bRec)

	aCurrent = aCurrent or _G
	sOrigin = sOrigin or "_G"
	if (bRec == nil and (t == _G or _G[t])) then
		return "_G"
	end

	local sArray = string.gsub(tostring(aCurrent), "^table: ", "")
	if (bRec == nil) then
		table.__NO__RECURSION__ = {}
	elseif (table.__NO__RECURSION__[sArray] ~= nil) then
		return
	else
		table.__NO__RECURSION__[sArray] = 1
	end

	local sName
	local bFunction
	for i, v in pairs(aCurrent) do
		if (isArray(v)) then
			if (v == t) then
				sName = i
				if (bFullStack) then
					sName = sOrigin .. "." .. i
				end
				break
			else
				--						 t-origin-search-rec
				local r = (table.getorigin(t, bFullStack, sOrigin .. "[" .. tostring(i) .. "]", v, true))
				if (r) then
					sName = r
					break
				end
			end
		elseif (isFunc(v) or isUserdata(v) or isFile(v)) then
			if (v == t) then
				sName = i
				if (bFullStack) then
					sName = sOrigin .. "." .. i
				end
				break
			end
		end
	end

	if (bRec == nil) then
		table.__NO__RECURSION__ = {}
	end

	if (sName and bRec == nil) then
	end
	return sName
end

---------------------------
-- table.find

table.find = function(t, hFind)
	local c = 0
	for i, v in pairs(t) do
		c = c + 1
		if (i == hFind) then
			return v end
	end

	return
end

---------------------------
-- table.findv

table.findv = function(t, hFind)
	local c = 0
	for i, v in pairs(t) do
		c = c + 1
		if (v == hFind) then
			return v end
	end
	 
	return
end

---------------------------
-- table.findex

table.findex = function(t, hFind)
	local c = 0
	for i, v in pairs(t) do
		c = c + 1
		if (i == hFind or v == hFind) then
			return v end
	end
	 
	return
end

---------------------------
-- table.findall

table.findall = function(t, ...)

	local aFind = { ... }
	if (table.count(aFind) == 0) then
		return end

	for i, v in pairs(aFind) do
		if (not table.find(t, v)) then
			return false end
	end
	 
	return true
end

---------------------------
-- table.findany

table.findany = function(t, ...)

	local aFind = { ... }
	if (table.count(aFind) == 0) then
		return end

	for i, v in pairs(aFind) do
		local hFound = table.find(t, v)
		if (hFound) then
			return hFound end
	end
	 
	return
end

---------------------------
-- table.index

table.index = function(t, iIndex)
	local c = 0
	for i, v in pairs(t) do
		c = c + 1
		if (c == iIndex) then
			return v end
	end
	 
	return
end

---------------------------
-- table.indexname

table.indexname = function(t, iIndex)
	local c = 0
	for i, v in pairs(t) do
		c = c + 1
		if (c == iIndex) then
			return i end
	end
	 
	return
end

---------------------------
-- table.append

table.append = function(t1, ...)

	for _, t in pairs({ ... }) do
		for __, _t in pairs(t) do
			table.insert(t1, _t)
		end
	end

	-- for _, v in ipairs(t2) do
		-- table.insert(t1, v)
	-- end
	return t1
end

---------------------------
-- table.shuffle

table.shuffle = function(t1)

	if (not table.isarray(t1)) then
		return t1 end

	local tNew = {}
	local aIndexes = {}

	for i, v in pairs(t1) do
		table.insert(aIndexes, i) end
	
	for i = 1, table.count(t1) do
	
		local iNewIndex = getrandom(1, table.count(aIndexes))
	
		table.insert(tNew, t1[aIndexes[iNewIndex]]) 
		table.remove(aIndexes, iNewIndex) 
	end
	
	return tNew
end

---------------------------
-- table.arrayShiftZero

table.arrayShiftZero = function(t1,t2)
	
	if (t2 == nil) then
		t2 = t1 end

	for i = 0, (#t1 - 1) do
		t2[i] = t1[i + 1] end
		
	t2[#t1] = nil
end

---------------------------
-- table.arrayShiftOne

table.arrayShiftOne = function(t1, t2)
	
	if (t2 == nil) then
		t2 = t1 end

	for i = #t1 + 1, 1, -1 do
		t2[i] = t1[i - 1] end
		
	t2[0] = nil
end

---------------------------
-- table.tostring (!!MESSY!!)

table.tostring = function(aArray, sTab, sName, bSubCall)

	if (sTab == nil) then
		sTab = "" end
		
	if (sName == nil) then
		sName = tostring(aArray) .. " = " end
		
	local sArray = string.gsub(tostring(aArray), "^table: ", "")
	if (bSubCall == nil) then
		table.__NO__RECURSION__ = {}
	elseif (table.__NO__RECURSION__[sArray] ~= nil) then
		return
	else
		table.__NO__RECURSION__[sArray] = 1
	end
		
	local sRes = sTab .. sName .. "{\n"
	local sTabBefore = sTab
	sTab = sTab .. " "
	
	local bRec, sRec = false, ""
	
	for i, v in pairs(aArray or {}) do
	
		bRec, sRec = false, ""
		
		local vType = type(v)
		local vKey = "[" .. tostring(i) .. "] = "
		if (type(i) == "string") then
			vKey = "[\"" .. tostring(i) .. "\"] = " end
				
		if (vType == "table") then
			sRec = (table.tostring(v, sTab, "[\"" .. tostring(i) .. "\"] = ", aArray, 1))
			if (string.empty(sRec)) then
				bRec = true
			else
				sRes = sRes .. sRec
			end	
		elseif (vType == "number") then
			sRes = sRes .. sTab .. vKey .. string.format("%f", v)
		elseif (vType == "string") then
			sRes = sRes .. sTab .. vKey .. "\"" .. v .. "\""
		else
			sRes = sRes .. sTab .. vKey .. tostring(v)
		end
		
		if (not bRec) then
			sRes = sRes .. ",\n"
		end
	end

	sRes = sRes .. sTabBefore .. "}"

	if (bSubCall == nil) then
		table.__NO__RECURSION__ = {} 
	end
	return sRes
end

-------------------

arrayutils.one = table.one
arrayutils.copy = table.copy
arrayutils.empty = table.empty
arrayutils.count = table.count
arrayutils.getsize = table.count
arrayutils.lookup = table.lookup
arrayutils.select = table.select
arrayutils.append = table.append
arrayutils.popLast = table.popLast
arrayutils.iselect = table.iselect
arrayutils.lookupk = table.lookupk
arrayutils.isarray = table.isarray
arrayutils.countRec = table.countRec
arrayutils.tostring = table.tostring
arrayutils.popFirst = table.popFirst
arrayutils.contains = table.contains
arrayutils.deepCopy = table.deepCopy
arrayutils.lookupRec = table.lookupRec
arrayutils.deepClone = table.deepClone
arrayutils.insertFirst = table.insertFirst
arrayutils.removeValue = table.removeValue
arrayutils.shallowClone = table.shallowClone
arrayutils.arrayShiftOne = table.arrayShiftOne
arrayutils.arrayShiftZero = table.arrayShiftZero
arrayutils.removeWithPredicate = table.removeWithPredicate

-------------------
return arrayutils