--=====================================================
-- CopyRight (c) R 2022-2203
--
-- a wowomg-algorithm to shred and decrypt shredded string
-- can also be 'secured' with salt/key
--
--=====================================================


-------------------------------------------------------
-- CONVERTED FROM AU3 TO LUA
-- !!!!!!!!!!! LEGACY SCRIPTS !!!!!!!!


-------------------------------------------------------
stringshredder = {
	version = "1.0",
	author = "shortcut0",
	description = "an algrithm to encrypt and decrypt string by seemingly completely randomizing the product. quite effective, pretty fast and somewhat secure." 
}

-- Splits a string into individual characters
local function StringSplit(sString)
    local aRes = {}
    for i = 1, string.len(sString) do
        aRes[i] = string.sub(sString, i, i)
    end
    return aRes
end

-- Calculates the key value from a string
local function CalculateKeyValue(sPassword, iSalt)
    local iSalt = (iSalt or 0)
    local iKey = 0
    local iPrime = 257 -- A prime number close to 256 for enhanced randomness
    for i = 1, string.len(sPassword) do
        local iCharCode = string.byte(sPassword, i)
        iKey = (iKey + iCharCode + iSalt) * iPrime -- Simple mixing operation with a prime multiplier
    end
    print(iKey)
    return iKey
end

-- Scrambles a string using a key
stringshredder.ShredString = function(sString, sKey, iSalt)
    sKey = sKey or ""
    local aString = StringSplit(sString)
    local iStringLen = #aString
    local iCryptKey = CalculateKeyValue(sKey, iSalt)

    for i = 1, iStringLen do
        local iCryptAdd = i + iStringLen % 100 + iCryptKey
        local iIndexReplace = (i + iCryptAdd) % iStringLen + 1
        aString[i], aString[iIndexReplace] = aString[iIndexReplace], aString[i]
    end

    return table.concat(aString)
end

-- Unscrambles a string using a key
stringshredder.DecryptString = function(sString, sKey, iSalt)
    sKey = sKey or ""
    local aString = StringSplit(sString)
    local iStringLen = #aString
    local iCryptKey = CalculateKeyValue(sKey, iSalt)

    for i = iStringLen, 1, -1 do
        local iCryptAdd = i + iStringLen % 100 + iCryptKey
        local iIndexReplace = (i + iCryptAdd) % iStringLen + 1
        aString[i], aString[iIndexReplace] = aString[iIndexReplace], aString[i]
    end

    return table.concat(aString)
end

-------------------------------------------------------
if (string) then
	string.legacy_shredder = legacy_stringshredder 	
	string.shredder = stringshredder 	
end