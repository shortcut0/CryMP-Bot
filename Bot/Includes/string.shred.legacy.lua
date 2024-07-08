--=====================================================
-- CopyRight (c) R 2022-2203
--
-- a wowomg-algorithm to shred and decrypt shredded string
-- can also be 'secured' with salt/key
--
--=====================================================


-------------------------------------------------------
-- CONVERTED FROM AU3 TO LUA
local stringshredder = {
	version = "1.0",
	author = "shortcut0",
	description = "an algrithm to encrypt and decrypt string by seemingly completely randomizing the product. quite effective, pretty fast and somewhat secure." 
}

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

local function StringLeft(sString, iLeft)
	if (not iLeft) then
		return "" end
		
	local sLeft = string.sub(sString, 1, iLeft)
	return sLeft
end

-------------------------------------------------------
-- CONVERTED FROM AU3 TO LUA

local function StringRight(sString, iRight)
	if (not iRight) then
		return "" end
		
	local iLen = string.len(sString)
	local sRight = string.sub(sString, (iLen - iRight) + 1, iLen)
	return sRight
end

-------------------------------------------------------
local function CalculateKeyValue(sKey)
	local iKey = 0
	for i, v in pairs(StringSplit(sKey)) do
		iKey = iKey + (string.byte(v) or 0)
	end
	return iKey
end

-------------------------------------------------------
local function CalcIndex(num, target)
	local f = num / target
	if (target > num or f < 1) then
		return { 0, num }
	end
	local fits = string.gsub(f, "%.(.*)", "")
	local rem = num - (fits * target)
	return { fits, rem }
end

-------------------------------------------------------
stringshredder.ShredString = function(sString, sKey)
	if (not sKey) then
		sKey = "" end

	-- Split the message into single characters
	local aString = StringSplit(sString, "")
	local iString = string.len(sString)
	local iString0 = iString

	-- The Cryptic key required to decrypt the string
	iCryptKey = CalculateKeyValue(sKey)

	-- Set up the initial Cryptic Key
	local iCryptAdd = 0
	local iCryptAdd_Extra = 1
	local iCryptAdd_Key = 0


	-- Some variables
	local sChar_Take, sChar_Replace, iIndex_Replace, iIndex_Take

	-- Encrypt each character
	for i = 1, iString0 do

		-- Key Randomizer to ensure perfect encryption
		iCryptAdd_Extra = StringRight(i, 2) + StringRight(i, 1) + StringLeft(i, 1)
		if (iCryptAdd_Extra > 255) then
			iCryptAdd_Extra = StringLeft(i, 2)
		end

		-- Crypt Key Add
		if (iCryptKey > 0) then
			iCryptAdd_Key = iCryptKey + StringLeft(iCryptKey, 2) + StringRight(iCryptKey, 2) - StringLeft(StringRight(iCryptKey, 4), 2) + (i * StringLeft(iCryptKey, 2))
		end

		-- Primary Crypt Randomizer
		iCryptAdd = i + StringRight(iString, 2) - StringLeft(iString, 1) + iCryptAdd_Key
		if (iCryptAdd < 0) then 
			iCryptAdd = iCryptAdd * -1 end

		-- Calculate the seemingly "random" new index
		iIndex_Take = i
		iIndex_Replace = i + iCryptAdd_Extra + iCryptAdd
		if (iIndex_Replace > iString0) then
			iIndex_Replace = CalcIndex(iIndex_Replace, iString0)[2] + 1
		end
		-- Retrive the character from the array
		sChar_Take 		= aString[i]
		sChar_Replace 	= aString[iIndex_Replace]

		-- print a debug message for shortcut
		-- print("[E] Index " .. i .. ", Was " .. sChar_Take .. ", Now is " .. sChar_Replace .. ", Index " .. i .. ", Now is: " .. iIndex_Replace .. ", Add = " .. iCryptAdd_Extra .. ", " .. iCryptAdd)


		-- Replace the characters
		aString[i] = sChar_Replace
		aString[iIndex_Replace] = sChar_Take
	end

	-- Rebuild the string
	local sCrypt = ""
	for i, v in pairs(aString) do
		sCrypt = sCrypt .. v
	end

	-- Return the chopped string
	return sCrypt
end

-------------------------------------------------------
stringshredder.DecryptString = function(sString, sKey)
	if (not sKey) then
		sKey = "" end

	-- Split the message into single characters
	local aString = StringSplit(sString, "")
	local iString = string.len(sString)
	local iString0 = iString

	-- The Cryptic key required to decrypt the string
	iCryptKey = CalculateKeyValue(sKey)

	-- Set up the initial Cryptic Key
	local iCryptAdd = 0
	local iCryptAdd_Extra = 1
	local iCryptAdd_Key = 0


	-- Some variables
	local sChar_Take, sChar_Replace, iIndex_Replace, iIndex_Take

	-- Encrypt each character
	for i = iString0, 1, -1 do

		-- Key Randomizer to ensure perfect encryption
		iCryptAdd_Extra = StringRight(i, 2) + StringRight(i, 1) + StringLeft(i, 1)
		if (iCryptAdd_Extra > 255) then
			iCryptAdd_Extra = StringLeft(i, 2)
		end

		-- Crypt Key Add
		if (iCryptKey > 0) then
			iCryptAdd_Key = iCryptKey + StringLeft(iCryptKey, 2) + StringRight(iCryptKey, 2) - StringLeft(StringRight(iCryptKey, 4), 2) + (i * StringLeft(iCryptKey, 2))
		end

		-- Primary Crypt Randomizer
		iCryptAdd = i + StringRight(iString, 2) - StringLeft(iString, 1) + iCryptAdd_Key
		if (iCryptAdd < 0) then 
			iCryptAdd = iCryptAdd * -1 end

		-- Calculate the seemingly "random" new index
		iIndex_Take = i
		iIndex_Replace = i + iCryptAdd_Extra + iCryptAdd
		if (iIndex_Replace > iString0) then
			iIndex_Replace = CalcIndex(iIndex_Replace, iString0)[2] + 1
		end

		-- Retrive the character from the array
		sChar_Take 	= aString[i]
		sChar_Replace 	= aString[iIndex_Replace]
		

		-- print a debug message for shortcut
		-- print("[D] Index " .. i .. ", Was " .. sChar_Take .. ", Now is " .. sChar_Replace .. ", Index " .. i .. ", Now is: " .. iIndex_Replace .. ", Del = " .. iCryptAdd_Extra .. ", " .. iCryptAdd)

		-- Replace the characters and move them to their original position
		aString[i] = sChar_Replace
		aString[iIndex_Replace] = sChar_Take

	end

	-- Rebuild the string
	local sCrypt = ""
	for i, v in pairs(aString) do
		sCrypt = sCrypt .. v
	end

	-- Return the string
	return sCrypt
end


-------------------------------------------------------
if (string) then
	string.shredder = stringshredder 	
end