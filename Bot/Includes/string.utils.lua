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
	while tempFile do
		retries = retries + 1
		tempFile:close()
		tempName = string.new(string.removefileextension(name)) .. " (" .. retries .. ")" .. ext--string.getfileextension(name)
		tempFile = io.open(tempName, "r")
	end
	
	if (tempFile) then tempFile:close() end
	
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
-- string.getvar

string.getvar = function(sVar, bNoHandleMethod)

	local sResult = ""
	if (not bNoHandleMethod) then
		-- The correct approach
		local handle = io.popen("echo %" .. sVar .. "%")
		if (not handle) then
			return
		end
		local sResult = handle:read"*l"
		handle:close()
	else
		-- The shitty approach
		local sFile = string.makefilename("_echo_out_temp.txt")
		os.execute("echo %" .. sVar .. "% > \"" .. sFile .. "\"")
		local hFile = io.open(sFile, "r")
		sResult = hFile:read"*all"
		hFile:close()
		os.execute("del \"" .. sFile .. "\"")
	end
	
	return sResult
end

---------------------------
-- string.getval

string.getval = function(sVal, bNoHandleMethod)

	local sResult = ""
	if (not bNoHandleMethod) then
		-- The correct approach
		local handle = io.popen(sVal)
		if (not handle) then
			return
		end
		local sResult = handle:read"*l"
		handle:close()
	else
		-- The shitty approach
		local sFile = string.makefilename("_proc_out_temp.txt")
		os.execute(sVal .. " > \"" .. sFile .. "\"")
		local hFile = io.open(sFile, "r")
		sResult = hFile:read"*all"
		hFile:close()
		os.execute("del \"" .. sFile .. "\"")
	end
	
	return sResult
end

---------------------------
-- string.getworkingdir

string.getworkingdir = function() return os.getvar("cd") end

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

string.lspace = function(s, space)

	return string.rep(" ", space - string.len(s)) .. s

end

---------------------------
-- string.mspace

string.mspace = function(s, space)

	local s_len = s:len() / (s_len_div or 1);
	local side_len = math.floor((space / 2) - (s_len / 2));
	
	local add = side_len * 2 + s_len < space;
	return string.rep(" ", math.floor(side_len)) .. s .. string.rep(" ", add and side_len + 1 or side_len);

end

---------------------------
-- string.lspace

string.rspace = function(s, space)

	return s .. string.rep(" ", space - string.len(s))

end

---------------------------
-- string.clean

string.clean = function(s, pattern)
	local s = string.new(s)
	local result = "";
	local cleanPattern = pattern or "[a-zA-Z0-9_'{}\"%(%) %*&%%%$#@!%?/\\;:,%.<>%-%[%]%+]";
	for i = 1, string.len(s) do
		local s = string.sub(s, i, i);
		if(s and string.match(s, cleanPattern))then
			result = result .. s;
		end;
	end;
	return result;

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
	
	local sFormat = "%" .. iLen .. "x"
	return string.upper(string.gsub(string.format(sFormat, iNumber), " ", 0))
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


-------------------
stringutils.hex = string.hex
stringutils.new = string.new
stringutils.cut = string.cut
stringutils.clean = string.clean
stringutils.valid = string.valid
stringutils.split = string.split
stringutils.random = string.random
stringutils.rspace = string.rspace
stringutils.mspace = string.mspace
stringutils.lspace = string.lspace
stringutils.getdir = string.getdir
stringutils.reverse = string.reverse
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
return stringutils