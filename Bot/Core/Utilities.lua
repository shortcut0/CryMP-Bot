--=====================================================
-- CopyRight (c) R 2024-2025
--
-- UTILITIES FOR THE CRYMP-BOT PROJECT
--
--=====================================================

---------------
GET_ALL = 1

---------------
--- Get Players
GetPlayers = function(bBots)
    local aPlayers = {}
    for i, hEntity in pairs(GetEntities("Player")) do
        if (hEntity.actor:IsPlayer() or checkVar(bBots, true)) then
            table.insert(aPlayers, hEntity)
        end
    end
    return (aPlayers or {})
end

---------------
--- Get Players
GetEntity = function(idEntity)

    ----------
    if (isNull(idEntity)) then
        return end

    ----------
    local hEntity = nil
    if (isString(idEntity)) then
        hEntity = System.GetEntityByName(idEntity)
    elseif (isArray(idEntity)) then
        hEntity = System.GetEntity(idEntity.id)
    elseif (isNumber(idEntity) or isEntityId(idEntity)) then
        hEntity = System.GetEntity(idEntity)
    end

    ----------
    return hEntity
end

---------------
--- Get Players

Countdown = function(fFunc, iTimes, iDelay, ...)

    local aArgs = { ... }
    if (not isFunc(fFunc)) then
        return
    end

    if (not isNumber(iTimes) or iTimes < 0) then
        return
    end

    for i = 1, iTimes do
        if (isNumber(iDelay)) then
            Script.SetTimer(i * iDelay, function()
                fFunc(unpack(aArgs))
            end)
        else
            fFunc(...)
        end
    end
end

---------------
--- Get Players
CheckEntity = function(idEntity)
    return (GetEntity(idEntity) ~= nil)
end

---------------
--- Get Players
GetEntities = function(sClass, sMember)

    ----------
    local aEntities
    if (sClass == GET_ALL) then
        aEntities = System.GetEntities()
    else
        aEntities = System.GetEntitiesByClass(sClass)
    end

    ----------
    if (not isArray(aEntities)) then
        return {} end

    ----------
    if (not sMember) then
        return aEntities end

    ----------
    local aNewEntities = table.iselect(aEntities, function(v) return (not isNull(v[sMember]))  end)
    return aNewEntities
end