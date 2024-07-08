--=====================================================
-- CopyRight (c) R 2024-2025
--
-- UTILITIES FOR THE CRYMP-BOT PROJECT
-- Credis: Sakura
--=====================================================

BotCVars = {}
BotCVars.g_pGameCVars = {}

----------
local fAddCommand = System.AddCCommand

----------
--- Dot
BotCVars.GetCVarIndex = function(sCVar)
    local sID
    for sName, pValue in pairs(BotCVars.g_pGameCVars) do
        if (string.lower(sName) == string.lower(sCVar)) then
            sID = sName
        end
    end
    return sID
end

----------
--- Dot
BotCVars.SetCVar = function(sCVar, pValue, bIsNumber)
    local sIndex = BotCVars.GetCVarIndex(sCVar)
    if (not sIndex) then
        return System.LogAlways(string.format("$6[Warning] Unknown command: %s", tostring(sCVar)))
    end

    local pValue = pValue
    local sValue = "\"" .. tostring(pValue) .. "\""

    if (bIsNumber) then
        pValue = tonumber(pValue)
        sValue = pValue
    end

    local sGlobal = BotCVars.g_pGameCVars[sIndex][2]
    local sCallback = BotCVars.g_pGameCVars[sIndex][3]
    if (pValue ~= nil) then
        BotCVars.g_pGameCVars[sIndex][1] = pValue
        if (sGlobal ~= nil) then
            loadstring([[
                ]] .. sGlobal .. [[ = ]] .. sValue .. [[
            ]])()
        end
        if (sCallback ~= nil and checkGlobal(sCallback)) then
            loadstring(string.format([[
                %s(%s)
            ]], sCallback, sValue))()
        end
    end
    System.LogAlways(string.format("   $3%s = $6%s $5[%s%s]", sIndex, tostring(BotCVars.g_pGameCVars[sIndex][1]), string.upper(type(BotCVars.g_pGameCVars[sIndex][1])), (sGlobal and (", G:" .. sGlobal) or "")))
end

----------
--- Dot
BotCVars.GetCVar = function(sCVar)

    if (BotCVars.g_pGameCVars[sCVar]) then
        return BotCVars.g_pGameCVars[sCVar][1]
    end

    local sIndex = BotCVars.GetCVarIndex(sCVar)
    if (sIndex) then
        return
    end
    return BotCVars.g_pGameCVars[sIndex][1]
end

----------
--- Dot
BotCVars.AddCVar = function(sCVar, sDesc, pDefault, bNumber, pGlobal, pCallback)
    BotCVars.g_pGameCVars[sCVar] = { checkVar(pDefault, 0), pGlobal, pCallback }
    if (checkGlobal(pGlobal) and pDefault) then
        local sDefault = "\"" .. tostring(pDefault) .. "\""
        if (bNumber) then
            sDefault = pDefault
        end
        loadstring(string.format([[
            %s=%s
        ]], pGlobal, sDefault))()
    end

    fAddCommand(sCVar, [[ local aArgs = { checkVar(%%) } BotCVars.SetCVar(']] .. sCVar .. [[', aArgs[1], ]] .. (bNumber and "true"or"false") .. [[) ]], sDesc)
end

----------
--- Dot
BotCVars.AddCommand = function(sName, sDesc, sFunc)
    fAddCommand(sName, [[ local aArgs = { checkVar(%%) } ]] .. sFunc .. [[(aArgs[1])]], sDesc)
end

----------
SetCVar = BotCVars.SetCVar
AddCVar = BotCVars.AddCVar
AddCommand = BotCVars.AddCommand