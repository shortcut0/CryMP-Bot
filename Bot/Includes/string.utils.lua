--=====================================================
-- CopyRight (c) R 2022-2203
--
-- Random (sometimes) useful string utils for lua
--
--=====================================================

-------------------
stringutils = {
	version = "1.0",
	author = "shortcut0",
	description = "all kinds of utiliy functions that might come in handy",
	requires = "math.utils.lua;"
}

---------------------------

string.NA = "N/A"
string.UNKNOWN = "<Unknown>"
string.INVALID = "<Invalid>"
string.ERROR = "<Error>"
string.WARNING = "<Warning>"
string.FAILED = "<Failed>"
string.TBFAILED = "<Tb Failed>"
string.EMPTY = "<Empty>"

string.COLOR_CODE = "%$%d"

---------------------------
-- string.swap

string.new = function(s)
	return "" .. (s or "")
end

---------------------------
-- string.valid

string.valid = function(s)
	return (s ~= nil and string.gsub(s, " ", "") ~= "")
end

---------------------------
-- string.getfileextension

string.getfileextension = function(s)
	return string.new(string.match(s, "^.+(%..+)$"))
end

---------------------------
-- string.removefileextension

string.removefileextension = function(s)
	local ext = string.getfileextension(s)
	local result = string.new(s)
	if (string.valid(s)) then
		result = string.gsub(result, ext .. "$", "")
	end
	return result
end

---------------------------
-- string.getfileextension

string.makefilename = function(name)

	local name = string.new(name)
	local tempName = string.new(name)
	local ext = string.getfileextension(name)

	local tempFile = io.open(tempName, "r")

	local retries = 0
	while (tempFile) 
	do
		retries = retries + 1
		tempFile:close()
		tempName = string.new(string.removefileextension(name)) .. " (" .. retries .. ")" .. ext--string.getfileextension(name)
		tempFile = io.open(tempName, "r")
	end
	
	if (tempFile) then 
		tempFile:close() end
	
	return tempName
end

---------------------------
-- string.openfile

string.openfile = function(name, options)

	local name = string.makefilename(string.new(name))
	local file, error = io.open(name, options)
	
	return file, error
end

---------------------------
-- string.getvar (eg: cd)

string.getvar = function(sVar, bNoHandleMethod)

	local sResult = ""
	if (not bNoHandleMethod and string.LUA_POPEN_SUPPORTED) then
		-- The correct approach
		local handle = io.popen("echo %" .. sVar .. "%")
		if (handle) then
			sResult = handle:read"*all"
			handle:close()
		end
	else
		-- The shitty approach
		local sFile = string.makefilename("_echo_out_temp.txt")
		os.execute("echo %" .. sVar .. "% > \"" .. sFile .. "\"")
		local hFile = io.open(sFile, "r")
		if (hFile) then
			sResult = hFile:read"*all"
			hFile:close() end

		os.execute("del \"" .. sFile .. "\"")
	end
	
	return string.gsub(sResult, "\n$", "")
end

---------------------------
-- string.getval (eg: dir/f)

string.getval = function(sVal, bNoHandleMethod, bUseFileOut)

	---------
	local sResult = ""
	local sCommand = sVal
	
	---------
	if (not bNoHandleMethod and string.LUA_POPEN_SUPPORTED) then
	
		------
		if (not bUseFileOut and string.find(sCommand, "{file_out}")) then
			sCommand = string.gsub(sCommand, "{file_out}", "") end
		
		------
		local handle = io.popen(string.rtws(sCommand))
		if (handle) then
			sResult = handle:read"*all"
			handle:close() end
	else
		-- The shitty approach
		local sFile = string.makefilename(string.gettempdir() .. "\\temp_read")
		if (bUseFileOut and string.find(sCommand, "{file_out}")) then
			sCommand = string.gsub(sCommand, "{file_out}", (">> \"" .. sFile .. "\"")) else 
			sCommand = (string.gsub(sCommand, "{file_out}", "") .. " >> \"" .. sFile .. "\"")
		end
		
		------
		-- print("sCommand -> '" .. sCommand .. "'")
		-- PuttyLog("CommandLine: " .. sCommand)
		
		------
		os.execute(string.rtws(sCommand))
		local hFile = io.open(sFile, "r")
		if (hFile) then
			-- print("file ok")
			sResult = hFile:read"*all"
			hFile:close() end

		------
		os.execute("del \"" .. sFile .. "\"")
	end
	
	---------
	sResult = string.gsub(sResult, "(\n+)$", "")
	sResult = string.gsub(sResult, "(%s+)$", "")
	
	---------
	-- print("res --> '" .. sResult .. "'")
	
	---------
	return (sResult)
end

---------------------------
-- string.rtws

string.rtws = function(sString) 
	local sCleaned = string.new(sString)
	
	sCleaned = string.gsub(sCleaned, "(\n+)$", "")
	sCleaned = string.gsub(sCleaned, "(\t+)$", "")
	sCleaned = string.gsub(sCleaned, "(%s+)$", "")
	
	return sCleaned
end

---------------------------
-- string.getworkingdir

string.getworkingdir = function() return string.getvar("cd") end

---------------------------
-- string.getuserdir

string.getuserdir = function() return os.getenv("userprofile") end

---------------------------
-- string.getwindir

string.getwindir = function() return os.getenv("windir") end

---------------------------
-- string.gettempdir

string.gettempdir = function() return os.getenv("temp") end

---------------------------
-- string.getusername

string.getusername = function() return os.getenv("username") end

---------------------------
-- string.getdomainname

string.getdomainname = function() return os.getenv("userdomain") end

---------------------------
-- string.getalphabet

string.getalphabet = function()
	local sAlpha = "abcdefghijklmnopqrstuvwxyz";
	return sAlpha;
end

---------------------------
-- string.getchars

string.getchars = function()
	-- string.char(0/255)
	local sChars = "☺☻♥♦♫☼►◄↕‼¶§▬↨↑↓→←∟↔▲▼ !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~⌂ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ¢£¥₧ƒáíóúñÑªº¿⌐¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀αßΓπΣσµτΦΘΩδ∞φε∩≡±≥≤⌠⌡÷≈°∙·√ⁿ²■ ";
	return sChars;
end

---------------------------
-- string.cut

string.cut = function(s, _start, _end)
	local before, middle, after = string.sub(s, 0, _start), string.sub(s, _start + 1, _end), string.sub(s, _end + 1)
	return before, middle, after
end

---------------------------
-- string.reverse

string.reverse = function(s, _start, _end)

	local result = ""
	local s = string.new(s)
	
	if (string.len(s) <= 1) then
		return s
	end
	
	local _start, _end = tonumber(_start) or 0, tonumber(_end) or 999;
	local a, b, c = string.cut(s, _start, _end);
	local s_len = string.len(b)

	for i = s_len, 1, -1 do
		result = result .. b:sub(i, i)
	end
	
	return string.new(a) .. result .. string.new(c);

end

---------------------------
-- string.rspace

string.lspace = function(s, space, sClean, sChar)

	------------
	local iLen = string.len(s)
	if (sClean) then
		iLen = string.len(string.gsub(s, sClean, "")) end
		
	------------
	return string.rep(checkVar(sChar, " "), space - iLen) .. s

end

---------------------------
-- string.mspace

string.mspace = function(s, space, s_len_div, bClean, sChar)

	------------
	local iLen = string.len(s)
	if (sClean) then
		iLen = string.len(string.gsub(s, sClean, "")) end
		
	------------
	local s_len = (iLen) / (s_len_div or 1);
	local side_len = math.floor((space / 2) - (s_len / 2));
	
	local add = side_len * 2 + s_len < space;
	return string.rep(checkVar(sChar, " "), math.floor(side_len)) .. s .. string.rep(checkVar(sChar, " "), add and side_len + 1 or side_len);

end

---------------------------
-- string.lspace

string.rspace = function(s, space, sClean, sChar)

	------------
	local iLen = string.len(s)
	if (sClean) then
		iLen = string.len(string.gsub(s, sClean, "")) end
		
	------------
	return s .. string.rep(checkVar(sChar, " "), space - iLen)

end

---------------------------
-- string.lspace

string.repeats = function(s, iRepeats)

	--------
	if (not isNumber(iRepeats)) then
		return s end
		
	--------
	if (iRepeats <= 1) then
		return s end

	--------
	local sResult = s
	for i = 1, (iRepeats - 1) do
		sResult = sResult .. s
	end

	--------
	return sResult
end

---------------------------
-- string.replace

string.replace = function(s, iLen, sRepeater)

	--------
	if (not isNumber(iLen)) then
		return s end
		
	--------
	if (iLen < 1) then
		return s end

	--------
	local sResult = string.rep(checkVar(sRepeater, " "), (string.len(s) - iLen)) .. tostring(s)  

	--------
	return sResult
end

---------------------------
-- string.lreplace

string.lreplace = function(s, iLen, sRepeater)

	--------
	if (not isNumber(iLen)) then
		return s end
		
	--------
	if (iLen < 1) then
		return s end

	--------
	local sResult = tostring(s) .. string.rep(checkVar(sRepeater, " "), (string.len(s) - iLen))  

	--------
	return sResult
end

---------------------------
-- string.formatex

string.formatex = function(s, ...)

	--------
	if (#{...} > 0) then
		return (string.format(s, ...)) end

	--------
	return (s)
end

---------------------------
-- string.count

string.count = function(s, sFind)

	--------
	local sTemp, iOccurences = string.gsub(s, sFind, "")

	--------
	return (iOccurences)
end

---------------------------
-- string.findex

string.findex = function(s, ...)

	--------
	local aFind = { ... }
	if (table.count(aFind) == 0) then
		return end

	--------
	for i, sFind in pairs(aFind) do
		local a, b = string.find(s, sFind)
		if (a or b) then
			return a, b end
	end

	--------
	return
end

---------------------------
-- string.findand

string.findand = function(s, ...)

	--------
	local aFind = { ... }
	if (table.count(aFind) == 0) then
		return end

	--------
	local bFound = true
	for i, sFind in pairs(aFind) do
		local a, b = string.find(s, sFind)
		bFound = (bFound and (a and b))
	end

	--------
	return bFound
end

---------------------------
-- string.matchex

string.matchex = function(s, ...)

	--------
	local aMatch = { ... }
	if (table.count(aMatch) == 0) then
		return end

	--------
	for i, sMatch in pairs(aMatch) do
		local a = string.match(s, sMatch)
		if (a) then
			return a end
	end

	--------
	return
end

---------------------------
-- string.matchand

string.matchand = function(s, ...)

	--------
	local aMatch = { ... }
	if (table.count(aMatch) == 0) then
		return end

	--------
	local bMatched = true
	for i, sMatch in pairs(aMatch) do
		local a = string.match(s, sMatch)
		bMatched = (bMatched and (a))
	end

	--------
	return bMatched
end

---------------------------
-- string.gsubex

string.gsubex = function(s, aReplace, sReplacer)

	--------
	if (not sReplacer) then
		error("no replacer") end

	--------
	local aReplace = checkArray(aReplace, { aReplace })

	--------
	local sNew = string.new(s)
	for i, sReplace in pairs(aReplace) do
		local sReplacer_ = sReplacer
		sReplacer_ = string.gsub(sReplacer_, "{%%~0}", i)
		sReplacer_ = string.gsub(sReplacer_, "{%%~1}", sReplace)
		
		sNew = string.gsub(sNew, sReplace, sReplacer_)
	end

	--------
	return sNew
end

---------------------------
-- string.clean

string.clean = function(s, sPattern)
	local s = string.new(s)
	local sCleaned = "";
	local sCleanedPattern = (sPattern or "[a-zA-Z0-9_'{}\"%(%) %*&%%%$#@!%?/\\;:,%.<>%-%[%]%+]")
	for i = 1, string.len(s) do
		local s = string.sub(s, i, i)
		if (s and string.match(s, sCleanedPattern)) then
			sCleaned = sCleaned .. s end
	end
	return sCleaned

end

---------------------------
-- string.random

string.random = function(length, seed, only_seed)

	local sAlpha = string.getalphabet()
	local sAllChars = sAlpha .. string.upper(sAlpha)
	
	if (seed) then
		if (only_seed) then
			sAllChars = seed else
			sAllChars = sAllChars .. seed end
	end
	
	local iAllChars = string.len(sAllChars)
	local sResult = "";
	
	local iRandom;
	for i = 1, (length or 6) do
		iRandom = math.random(iAllChars)
		sResult = sResult .. string.sub(sAllChars, iRandom, iRandom) 
	end

	return sResult
end

---------------------------
-- string.randomize

string.randomize = function(s)

	local sResult = ""
	local keymap = { [0] = math.floor(math.random(1, 1000)) }
	
	local aChars = {}
	
	local iRandom;
	for i = 1, string.len(s) do
		iRandom = math.random(1, string.len(s))
		aChars [#aChars+1] = string.sub(s, iRandom, iRandom)
		
		local a, b, c = string.cut(s, iRandom - 1, iRandom)
		s = a .. c
	end
	
	sResult = table.concat(aChars, "")

	if (string.len(sResult) > 1 and sResult == s) then
		sResult, keymap = string.randomize(s)
	end

	return sResult
end

---------------------------
-- string.split

string.split = function(sString, sDelims)

	local iString = string.len(sString)

	if (not sDelims) then
		sDelims = "" end
		
	local iDelimsLen = string.len(sDelims)
	if (iDelimsLen <= 1) then
		iDelimsLen = 0 end
		
	local aRes = {}
	local sCollect = ""
	for i = 1, iString do
		local sChar = string.sub(sString, i, i + iDelimsLen)
		if (sDelims == "") then
			table.insert(aRes, sChar)
		elseif (sChar == sDelims) then
			table.insert(aRes, sCollect)
			sCollect = ""
		else
			sCollect = sCollect .. string.sub(sString, i, i)
		end
		
		if (sCollect ~= "" and i == iString) then
			table.insert(aRes, sCollect)
		end
	end
	return aRes

end

---------------------------
-- string.printarray

string.printarray = function(aArray, sTab, sName, aDone)

	if (sTab == nil) then
		sTab = "" end
		
	if (aDone == nil) then
		aDone = {} end
		
	if (sName == nil) then
		sName = tostring(aArray) .. " = " end
		
	local sRes = sTab .. sName .. "{\n"
	local sTabBefore = sTab
	sTab = sTab .. "\t"
	
	for i, v in pairs(aArray or {}) do
		local vType = type(v)
		local vKey = "[" .. tostring(i) .. "] = "
		if (type(i) == "string") then
			vKey = "[\"" .. tostring(i) .. "\"] = " end
				
		if (vType == "table") then
			sRes, aDone = sRes .. sTab .. vKey .. (string.printarray(v, sTab .. sTab, i, aArray))
		elseif (vType == "number") then
			sRes = sRes .. sTab .. vKey .. string.format("%f", v)
		elseif (vType == "string") then
			sRes = sRes .. sTab .. vKey .. "\"" .. v .. "\""
		else
			sRes = sRes .. sTab .. vKey .. tostring(v)
		end
		sRes = sRes .. ",\n"
	end

	sRes = sRes .. sTabBefore .. "}"
	return sRes
end

---------------------------
-- string.hexdecode
-- NOTE: this is WIP!

string.hexdecode = function(hex)
   return (hex:gsub("^0x",""):gsub("%x%x", function(digits) return string.char(tonumber(digits, 16)) end))
end

---------------------------
-- string.hexencode
-- NOTE: this is WIP!

string.hexencode = function(str)
   return "0x" .. string.gsub((string.gsub(str, ".", function(char) return string.format("%2x", char:byte()) end)):upper(), " ", 0)
end

---------------------------
-- string.hex

string.hex = function(iNumber, iLen)
	if (iLen == nil) then
		iLen = 4 end
	
	local sFormat = "%0" .. iLen .. "x"
	return string.upper(string.format(sFormat, iNumber))
end

---------------------------
-- string.fileread

string.fileread = function(sPath)
	local hFile = io.open(sPath, "r")
	if (not hFile) then
		return end
		
	---------
	local sData = hFile:read"*all"
	hFile:close()
	
	---------
	return sData
end

---------------------------
-- string.left

string.left = function(sString, iLeft)

	---------
	if (not iLeft) then
		return "" end
		
	---------
	local sLeft = string.sub(sString, 1, iLeft)
	return sLeft
end

---------------------------
-- string.right

string.right = function(sString, iRight)

	---------
	if (not iRight) then
		return "" end
		
	---------
	local iLen = string.len(sString)
	local sRight = string.sub(sString, (iLen - iRight) + 1, iLen)
	return sRight
end

---------------------------
-- string.trimleft

string.trimleft = function(sString, iLeft)

	---------
	if (not iLeft) then
		return sString end
		
	---------
	return string.sub(sString, (iLeft + 1))
end

---------------------------
-- string.trimright

string.trimright = function(sString, iRight)

	---------
	if (not iRight) then
		return sString end
		
	---------
	return string.sub(sString, 1, string.len(sString) - iRight)
end

---------------------------
-- string.ridtrail

string.ridtrail = function(sString, sChar)

	---------
	return string.gsub(sString,  string.escape(sChar) .. "$", "")
end

---------------------------
-- string.ridtrailex

string.ridtrailex = function(sString, ...)

	---------
	local aChars = { ... }
	if (table.count(aChars) == 0) then
		return sString end
		
	---------
	local sResult = sString
	for i, sChar in pairs(aChars) do
		sResult = string.gsub(sResult, string.escape(sChar) .. "$", "")
	end
	
	---------
	return sResult
end

---------------------------
-- string.ridlead

string.ridlead = function(sString, sChar)

	---------
	return string.gsub(sString, "^" .. string.escape(sChar), "")
end

---------------------------
-- string.ridleadex

string.ridleadex = function(sString, ...)

	---------
	local aChars = { ... }
	if (table.count(aChars) == 0) then
		return sString end
		
	---------
	local sResult = sString
	for i, sChar in pairs(aChars) do
		sResult = string.gsub(sResult, "^" .. string.escape(sChar), "")
	end
	
	---------
	return sResult
end

---------------------------
-- string.fileread

string.bytestring = function(sString)

	---------
	local sByte = ""
	for i, v in pairs(string.split(sString, "")) do
		sByte = sByte .. string.byte(v) end
		
	---------
	return sByte
end

---------------------------
-- string.tobytes

string.tobytes = function(sString)
	
	---------
	local aBytes = {}
	
	---------
	string.gsub(sString, ".", function(sChar) 
		table.insert(aBytes, string.byte(sChar)) 
	end)

	---------
	return aBytes
end

---------------------------
-- string.frombytes

string.frombytes = function(aBytes)
	
	---------
	local sString = ""
	
	---------
	if (isArray(aBytes)) then
		for i, iBytes in pairs(aBytes) do
			if (isNumber(iBytes) and (iBytes >= 0 and iBytes <= 255)) then
				sString = sString .. string.char(iBytes)
			end
		end
	end

	---------
	return sString
end

---------------------------
-- string.bool

string.bool = function(bOk, sYes, sNo)
	
	---------
	local sYes = checkVar(sYes, "true")
	local sNo = checkVar(sNo, "false")

	---------
	return (bOk == true and sYes or sNo)
end

---------------------------
-- string.stripws

string.stripws = function(sString)
	
	---------
	if (isNull(sString)) then
		return "" end
	
	---------
	return string.gsub(sString, "%s", "")
end

---------------------------
-- string.empty

string.empty = function(sString)
	
	---------
	if (isNull(sString)) then
		return true end
		
	---------
	return (string.stripws(sString) == "")
end

---------------------------
-- string.escape

string.escape = function(sString, aExtra)
	
	---------
	if (isNull(sString)) then
		return "" end
		
	---------
	local aEscapes = {
		"(", ")",
		"[", "]",
		"+", "-", "*", 
		"?", "%", "$", "^"
	}
	
	---------
	if (aExtra) then
		aEscapes = table.append(aEscapes, aExtra) end
	
	---------
	local sEscaped = string.new(sString)
	for i, sChar in pairs(aEscapes) do
		sEscaped = string.gsub(sEscaped, ("%" .. sChar), ("%%%" .. sChar))
	end
	
	---------
	return string.gsub(sEscaped, "(%%+)", "%%")
end

---------------------------
-- string.bytesuffix

string.bytesuffix = function(iBytes)
	
	---------
	local aSuffixes = { "bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB", "HB", "BB" }
	local iIndex = 1
	while (iBytes > 1023 and iIndex <= 10) 
	do
		iBytes = iBytes / 1024
		iIndex = iIndex + 1
	end
	
	---------
	if (not iNullCount) then
		if (iIndex == 1) then iNullCount = 0 else
			iNullCount = 2
		end
	end
	
	---------
	local sBytes = string.format(string.format("%%0.%df%%s", iNullCount), iBytes, ((not bNoSuffix) and (" " .. aSuffixes[iIndex]) or ""))
	return sBytes
	
end

---------------------------
-- string.numsuffix

string.numsuffix = function(iNumber)
	
	---------
	local aSuffixes = { ' ', 'k', 'M', 'B', 'T', ' quadrillion', ' quintillion', ' sextillion', ' septillion', ' octillion', ' nonillion', ' decillion' }
	local iIndex = 1
	while (iNumber >= 1000 and iIndex <= 12) 
	do
		iNumber = iNumber / 1000
		iIndex = iIndex + 1
	end
	
	---------
	if (not iNullCount) then
		if (iIndex == 1) then 
			iNullCount = 0 else
			iNullCount = 2
		end
	end
	
	---------
	local sBytes = string.format(string.format("%%0.%df%%s", iNullCount), iNumber, ((not bNoSuffix) and ("" .. aSuffixes[iIndex]) or ""))
	return sBytes
	
end

---------------------------
-- string.dotnumber

string.dotnumber = function(iNumber)
	
	---------
	if (iNumber <= 1000) then
		return iNumber end
	
	---------
	local sDotNum = string.gsub(iNumber, "%d%d%d", "%1.")
	sDotNum = string.ridtrail(sDotNum, ".")
	
	---------
	return (sDotNum)
	
end


---------------------------
-- string.ispopensupported

string.ispopensupported = function(iBytes)
	
	---------
	local f = function()
		local hHandle = io.popen("dir")
		if (hHandle) then
			hHandle:close() end
	end
	
	---------
	local bOk, sErr = pcall(f)
	if (not bOk and (string.find(sErr, "'popen' not supported"))) then
		return false end
		
	---------
	return true
end


-------------------
stringutils.hex = string.hex
stringutils.new = string.new
stringutils.cut = string.cut
stringutils.empty = string.empty
stringutils.clean = string.clean
stringutils.valid = string.valid
stringutils.split = string.split
stringutils.random = string.random
stringutils.rspace = string.rspace
stringutils.mspace = string.mspace
stringutils.lspace = string.lspace
stringutils.getdir = string.getdir
stringutils.repeats = string.repeats
stringutils.reverse = string.reverse
stringutils.stripws = string.stripws
stringutils.getchars = string.getchars
stringutils.fileread = string.fileread
stringutils.openfile = string.openfile
stringutils.randomize = string.randomize
stringutils.hexdecode = string.hexdecode
stringutils.hexencode = string.hexencode
stringutils.getwindir = string.getwindir
stringutils.gettempdir = string.gettempdir
stringutils.getuserdir = string.getuserdir
stringutils.printarray = string.printarray
stringutils.bytestring = string.bytestring
stringutils.getusername = string.getusername
stringutils.makefilename = string.makefilename
stringutils.getdomainname = string.getdomainname
stringutils.getworkingdir = string.getworkingdir
stringutils.getfileextension = string.getfileextension
stringutils.removefileextension = string.removefileextension

-------------------

string.LUA_POPEN_SUPPORTED = string.ispopensupported()
string.WORKING_DIR = string.getworkingdir()

-------------------
return stringutils