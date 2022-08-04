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

	local iCurrStep = 0
	local aChars = StringSplit(StringToHex(sString), '')
	local iChars = #aChars
	local iSteps = iChars / iHexBlocks
	if (iSteps < 1) then
		iSteps = 1 end
	
	local iBlock = 1
	local iCurr = 0
	local aCharBlocks = {}
	for i = 1, iHexBlocks do
		aCharBlocks[i] = { 0 } end
		
	for i = 1, iChars do
		table.insert(aCharBlocks[iBlock], (string.byte(aChars[i])))
		iCurr = iCurr + 1
		if (iCurr >= iSteps or (i == iChars)) then
			iBlock = iBlock + 1
			iCurr = 0
		end
	end
	
	local iHexNum = 0
	for i, aBlock in pairs(aCharBlocks) do
		for _i, iHex in pairs(aBlock) do
			iHexNum = iHexNum + iHex end
			
		sHashed = sHashed .. Hex(iHexNum, iHexBlocks)
	end

	-- for i = 1, iChars, iSteps do

		-- iCurrStep = iCurrStep + 1

		-- local iHexNum = 0
		-- local iTemp = math.floor(i)
		-- repeat
			-- print("	+" .. aChars[iTemp])
			-- iHexNum = iHexNum + string.byte(aChars[iTemp])
			-- iTemp = iTemp + 1
		-- until ((iTemp + 1) >= (i + iSteps))-- or (iTemp + 1) >= iChars)

		-- print("iHexNum -> " .. iHexNum)
		-- sHashed = sHashed .. Hex(iHexNum + iCurrStep, iHexBlocks)
	-- end

	return sHashed
end

-------------------------------------------------------

simplehash.hash = _SH_Hash
simplehash.StringToHex = StringToHex
simplehash.StringSplit = StringSplit

-------------------------------------------------------

return simplehash