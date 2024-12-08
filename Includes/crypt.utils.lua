--=====================================================
-- CopyRight (c) R 2022-2203
--
-- Random (sometimes) useful crypting utils for lua
--
--=====================================================

-------------------
crypt = {
	version = "1.0",
	author = "shortcut0",
	description = "all kinds of encrypting utility functiontions that might come in handy"
}

---------------------------
crypt.aBinaryCharacters = { 'A', 'B', 'C', 'D', 'E', 'F', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' }
crypt.aBinaryIndexes = { ["A"] = 1, ["B"] = 2, ["C"] = 3, ["D"] = 4, ["E"] = 5, ["F"] = 6, ["0"] = 7, ["1"] = 8, ["2"] = 9, ["3"] = 10, ["4"] = 11, ["5"] = 12, ["6"] = 13, ["7"] = 14, ["8"] = 15, ["9"] = 16 }


---------------------------
crypt.aCharSets = {
	["set_255"] = {},
	["set_253"] = {},
	["set_alpha"] = { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z' },
	["set_alphanum"] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T' },
	["set_binary"] = { 'A', 'B', 'C', 'D', 'E', 'F', 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
	["set_binarylow"] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 'a', 'b', 'c', 'd', 'e', 'f' },
	["set_special"] = { '!', '"', '§', '$', '%', '&', '/', '(', ')', '=', '?', '[', ']', '{', '}', '²', '³', "'", '*', '+', '~', '#', ',', ';', '.', ':', '-', '_', '<', '>', '|', '´', '`', '^', '°', '@' },
	["set_control"] = {},
	["set_print"] = {},
	["set_extended"] = {},
}

local iIndex_1, iIndex_2, iIndex_3 = 1, 1, 1
for i = 1, 255 do

	---------
	local sChar = string.char(i)
	
	---------
	crypt.aCharSets["set_255"][i] = sChar
	
	---------
	if (i <= 253) then
		crypt.aCharSets["set_253"][i] = sChar 
	end
		
	---------
	if (i <= 31 or i == 127) then
		crypt.aCharSets["set_control"][iIndex_1] = sChar
		iIndex_1 = iIndex_1 + 1
	end
	
	---------
	if (i > 31 and i < 127) then
		crypt.aCharSets["set_print"][iIndex_2] = sChar
		iIndex_2 = iIndex_2 + 1
	end
	
	---------
	if (i > 127) then
		crypt.aCharSets["set_extended"][iIndex_3] = sChar
		iIndex_3 = iIndex_3 + 1
	end
end

---------------------------
CALG_SCA_255 = 0x001
CALG_SCA_253 = 0x002
CALG_SCA_ALPHA = 0x003
CALG_SCA_ALPHANUM = 0x004
CALG_SCA_BINARY = 0x005
CALG_SCA_BINARYLOW = 0x006
CALG_SCA_SPECIAL = 0x007
CALG_SCA_CONTROL = 0x008
CALG_SCA_PRINT = 0x009
CALG_SCA_EXTENDED = 0x00A

---------------------------

crypt.DEFAULT_CRYPTING_ALGORITHM = CALG_SCA_255

---------------------------
-- crypt.encrypt

crypt.encrypt = function(sString, sKey, iCharSet)

	local sKey = checkVar(sKey, "")
	local iCharSet = checkVar(iCharSet, crypt.DEFAULT_CRYPTING_ALGORITHM)

	---------
	local sString = string.hexencode(sString)
	sString = string.trimleft(sString, 2)

	---------
	local aString = string.split(sString, "")
	local iString = string.len(sString)

	---------
	local aCharSet = crypt.GetCharSet(iCharSet)
	local iCharSetLen = table.count(aCharSet)
	if (iCharSetLen < 16) then
		BotMainLog("bad set, %d",iCharSetLen)
		return "-1"
	end
	
	---------
	crypt.AssignChars(aCharSet)

	---------
	local iCryptAdd = 1
	local iCryptAdd_Extra = 1

	---------
	iCryptAdd = iCryptAdd + crypt.CalculateKeyValue(sKey)

	---------
	local sChar, iBinary, iBinaryAdded, iCharIndex
	local sCrypt = ""

	---------
	for i = 1, iString do

		---------
		iCryptAdd_Extra = iCryptAdd_Extra + string.right(i, 2) + string.right(i, 1) + string.left(i, 1)
		if (iCryptAdd_Extra > 255) then
			iCryptAdd_Extra = string.left(i, 2)
		end

		---------
		sChar = aString[i]
		
		---------
		iBinary = crypt.GetBinaryIndex(sChar) + 1
		iBinaryAdded = iBinary + (iCryptAdd + i + iCryptAdd_Extra)
		
		---------
		--FinchLog("[E] iBinaryAdded --> %d (+%d)", iBinaryAdded, (iCryptAdd + i + iCryptAdd_Extra))
		
		---------
		iCharIndex = tonumber(math.loopindex(iBinaryAdded, iCharSetLen)[2])
		if (iCharIndex == 0) then
			iCharIndex = 1 end
		
		---------
		--FinchLog("[E] Index --> %d for char %s", iCharIndex, sChar)
		
		---------
		sCrypt = sCrypt .. aCharSet[iCharIndex]
	end

	--System.LogAlways("Encrypted -> " .. tostring(sCrypt))
	--System.LogAlways("EncryptedBinary -> " .. string.hexencode(sCrypt))

	---------
	return string.hexencode(sCrypt, 4)
end

---------------------------
-- crypt.encrypt

crypt.encryptfile = function(sFile, sKey, iCharSet)

	-----------
	local sFileData = string.fileread(sFile)

	-----------
	local hFile = io.open(sFile, "w+")
	if (not hFile) then
		return false end
		
	-----------
	hFile:write(string.hexdecode(crypt.encrypt(sFileData, sKey, iCharSet)))
	
	-----------
	hFile:close()
	
	-----------
	return true
end

---------------------------
-- crypt.decrypt

crypt.decrypt = function(sString, sKey, iCharSet)

	---------
	local self = crypt

	---------
	local sKey = checkVar(sKey, "")

	---------
	local sString = string.hexdecode(sString)
	local aString = string.split(sString, "", STR_NOCOUNT)
	local iString = string.len(sString)

	---------
	local iCharSet = checkVar(iCharSet, crypt.DEFAULT_CRYPTING_ALGORITHM)
	local aCharSet = self.GetCharSet(iCharSet)
	local iCharSetLen = table.count(aCharSet)
	if (iCharSetLen < 16) then
		return "-1"
	end

	---------
	local iCharsPerLoop = string.len(aCharSet[1])

	---------
	local iCryptAdd = 1
	local iCryptAdd_Extra = 1

	---------
	iCryptAdd = iCryptAdd + self.CalculateKeyValue(sKey)

	---------
	local sChar, iCharIndex, iBinaryIndex, ifits, iAdd
	local iMultisetSkip, iMultisetStep = 0, 0
	local sCrypt = ""

	---------
	self.AssignChars(aCharSet)

	---------
	local bStop = false
	for i = 1, iString do
		
		---------
		bStop = false
		
		---------
		iAdd = i

		---------
		if (iCharsPerLoop > 1) then
			iAdd = iMultisetStep
			if (i < iMultisetSkip) then -- Skip already processed characters
				bStop = true
			end
			
			if (not bStop) then
				iMultisetStep = iMultisetStep + 1
				sChar = aString[i]
				for i_add = 1, iCharsPerLoop - 1 do
					sChar = sChar .. aString[i + i_add] -- Append characters
				end
				iMultisetSkip = i + iCharsPerLoop -- Set end Skip-Mark
			end
		else
			sChar = aString[i]
		end

		---------
		if (not bStop) then
		
			---------
			iCryptAdd_Extra = iCryptAdd_Extra + string.right(iAdd, 2) + string.right(iAdd, 1) + string.left(iAdd, 1)
			if (iCryptAdd_Extra > 255) then
				iCryptAdd_Extra = string.left(iAdd, 2)
			end

			---------
			iCharIndex = self.CharGetIndex(sChar)
			if (iCharIndex == -1) then
				sCrypt = ""
				break
			end

			---------
			iBinaryIndex = (iCharIndex) - (iCryptAdd + iAdd + iCryptAdd_Extra)
		
			---------
			-- FinchLog("[D] char: '%s' iBinaryAdded --> %d (+%d)", sChar, iBinaryIndex, (iCryptAdd + iAdd + iCryptAdd_Extra))
			
			---------
			ifits = (iBinaryIndex / iCharSetLen) * -1
			if (string.find(ifits, ".")) then
				ifits = string.match(ifits, "(%d+)")
			end

			---------
			if (tonumber(ifits) > 0) then
				iBinaryIndex = iBinaryIndex + iCharSetLen * ifits
			end

			---------
			if (iBinaryIndex < 1) then
				iBinaryIndex = iBinaryIndex + iCharSetLen
			end

			---------
			if (iBinaryIndex > 16 or iBinaryIndex < 1) then
				self.DestroyChars(aCharSet)
				return "-1"
			end

			---------
			--FinchLog("[D] Index --> %d", iBinaryIndex)

			---------
			sCrypt = sCrypt .. self.GetBinaryChar(iBinaryIndex)
		end
	end

	---------
	self.DestroyChars(aCharSet)

	---------
	if (string.len(sCrypt) == 0) then
		return "-1"
	end

	--System.LogAlways("EncryptB -> " .. tostring(sCrypt))
	---------
	sCrypt = "0x" .. sCrypt
	sCrypt = string.hexdecode(sCrypt)

	---------
	--System.LogAlways("Decrypted -> " .. sCrypt)

	---------
	return sCrypt
end

---------------------------
-- crypt.decryptfile

crypt.decryptfile = function(sFile, sKey, iCharSet)

	-----------
	local sFileData = string.fileread(sFile)

	-----------
	local hFile = io.open(sFile, "w+")
	if (not hFile) then
		return false end
		
	-----------
	hFile:write(crypt.decrypt(string.hexencode(sFileData), sKey, iCharSet))
	
	-----------
	hFile:close()
	
	-----------
	return true
end

------------------------------------
-- crypt.CharGetIndex

crypt.CharGetIndex = function(sChar)

	---------
	local iIndex = (crypt.aCharacterSet[string.hexencode(sChar)])
	if (iIndex == 0) then
		return -1 end
		
	---------
	if (not isNumber(iIndex)) then
		return -1 end
	
	return iIndex - 1
end

------------------------------------
-- crypt.AssignChars

crypt.AssignChars = function(aSet)

	---------
	crypt.aCharacterSet = {}
	
	---------
	local iCounter = 0
	for i, v in pairs(aSet) do
		iCounter = iCounter + 1
		crypt.aCharacterSet[string.hexencode(v)] = iCounter
	end
end

------------------------------------
-- crypt.DestroyChars

crypt.DestroyChars = function(aSet)
	crypt.aCharacterSet = nil
end

------------------------------------
-- crypt.CalculateKeyValue

crypt.CalculateKeyValue = function(sKey)

	------------
	local iCryptKeyVal = 0

	------------
	if (isString(sKey) and not (sKey == "")) then

		------------
		local aKeyArray = string.tobytes(sKey)
		local aKeyArrayNum = table.count(aKeyArray)

		------------
		for i = 1, aKeyArrayNum do
			iCryptKeyVal = iCryptKeyVal + aKeyArray[i] + i end
	end

	------------
	return iCryptKeyVal + string.len(sKey)
end

------------------------------------
-- crypt.GetBinaryChar

crypt.GetBinaryChar = function(iIndex)
	return crypt.aBinaryCharacters[iIndex]
end

------------------------------------
-- crypt.GetBinaryIndex

crypt.GetBinaryIndex = function(sChar)
	return crypt.aBinaryIndexes[sChar]
end

------------------------------------
-- crypt.GetCharSet

crypt.GetCharSet = function(iSet)

	BotLog("iSet=%s(%s)",g_ts(iSet),type(iSet))
	if (iSet == CALG_SCA_255) then
		return crypt.aCharSets["set_255"]
		
	elseif (iSet == CALG_SCA_253) then
		return crypt.aCharSets["set_253"]
		
	elseif (iSet == CALG_SCA_ALPHA) then
		return crypt.aCharSets["set_alpha"]
		
	elseif (iSet == CALG_SCA_ALPHANUM) then
		return crypt.aCharSets["set_alphanum"]
		
	elseif (iSet == CALG_SCA_BINARY) then
		return crypt.aCharSets["set_binary"]
		
	elseif (iSet == CALG_SCA_BINARYLOW) then
		return crypt.aCharSets["set_binarylow"]
		
	elseif (iSet == CALG_SCA_CONTROL) then
		return crypt.aCharSets["set_control"]
		
	elseif (iSet == CALG_SCA_PRINT) then
		return crypt.aCharSets["set_print"]
		
	elseif (iSet == CALG_SCA_SPECIAL) then
		return crypt.aCharSets["set_special"]
	end
end

-------------------
return crypt