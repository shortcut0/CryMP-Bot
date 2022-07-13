--=====================================================
-- CopyRight (c) R 2022-2203
--
-- A random hashing function i made before i went to sleep one night
--
--=====================================================

-------------------
simplehash = {
	version = "1.0",
	author = "shortcut0",
	description = "a very simple, not well-working algrithm to hash string" 
}


-------------------------------------------------------
-- CONVERTED FROM AU3 TO LUA

local function StringSplit(sString, sDelims)
	if (not sDelims) then
		sDelims = "" end
		
	local iDelimsLen = string.len(sDelims)
	if (iDelimsLen < 0) then
		iDelimsLen = 0 end
		
	local aRes = {}
	local sCollect = ""
	for i = 1, string.len(sString) do
		local sChar = string.sub(sString, i, i + iDelimsLen)
		if (sDelims == "") then
			table.insert(aRes, sChar)
		elseif (sChar == sDelims) then
			table.insert(aRes, sCollect)
			sCollect = ""
		else
			sCollect = sCollect .. sChar
		end
	end
	return aRes
end

-------------------------------------------------------
-- CONVERTED FROM AU3 TO LUA

local function Hex(iNumber, iLen)
	if (iLen == nil) then
		iLen = 4 end
	
	local sFormat = "%" .. iLen .. "x"
	return string.upper(string.gsub(string.format(sFormat, iNumber), " ", 0))
end

-------------------------------------------------------
-- CONVERTED FROM AU3 TO LUA

local function StringToHex(str)
	return "0x" .. (str:gsub(".", function(char) return string.format("%2x", char:byte()) end)):upper()
end

-------------------------------------------------------
-- CONVERTED FROM AU3 TO LUA

function _SH_Hash(sString, iHexBlocks)
	if (iHexBlocks == nil) then
		iHexBlocks = 4 end

	local sHashed = ""

	local aChars = StringSplit(StringToHex(sString), '')
	local iChars = #aChars
	local iDividor = iHexBlocks
	local iSteps = iChars / iHexBlocks
	local iCurrStep = 0

	for i = 1, iChars, iSteps do

		iCurrStep = iCurrStep + 1

		local iHexNum = 0
		local iTemp = math.floor(i)
		repeat
			iHexNum = iHexNum + string.byte(aChars[iTemp])
			iTemp = iTemp + 1
		until (iTemp >= iChars)

		sHashed = sHashed .. Hex(iHexNum + iCurrStep, iHexBlocks)
	end

	return sHashed
end

-------------------------------------------------------

simplehash.hash = _SH_Hash
simplehash.StringToHex = StringToHex
simplehash.StringSplit = StringSplit

-------------------------------------------------------

return simplehash