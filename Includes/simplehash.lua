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
	description = "a very simple, not well-working algrithm to hash string",
	requires = "string.utils.lua;"
}

-------------------------------------------------------
-- CONVERTED FROM AU3 TO LUA

function _SH_Hash(sString, iHexBlocks)
	if (iHexBlocks == nil) then
		iHexBlocks = 4 end

	local sHashed = ""

	local iCurrStep = 0
	local aChars = string.split(string.hexencode(sString), '')
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
			
		sHashed = sHashed .. string.hex(iHexNum, iHexBlocks)
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

-------------------------------------------------------

return simplehash