--=====================================================
-- CopyRight (c) R 2024-2025
--
-- UTILITIES FOR THE CRYMP-BOT PROJECT
--
--=====================================================

---------------
GET_ALL = 1
ENTITY_ALL = 1

ENTITY_PLAYER = "Player"
ENTITY_ALIEN = "Alien"
ENTITY_HUNTER = "Hunter"
ENTITY_SCOUT = "Scout"
ENTITY_GRUNT = "Grunt"

ENTITY_DOOR = "Door"

---------------
RunCommand = function(self, sCommand)
    return os.execute(sCommand)
end

---------------
Assign = function(self, sVar, sVal)
    pcall(loadstring(string.formatex("%s = %s", sVar, sVal)))
end

---------------
fSORTBY_DISTANCE = function(a, b)
    local vPos = g_localActor:GetPos()
    return (vector.distance(a:GetPos(), vPos) < vector.distance(b:GetPos(), vPos))
end

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
GetEntities = function(sClass, sMember, fPred)

    ----------
    local aEntities
    if (sClass == GET_ALL) then
        aEntities = System.GetEntities()
    elseif (isArray(sClass)) then
        aEntities = {}
        for i, sEntity in pairs(sClass) do
            aEntities = table.append(aEntities, unpack(System.GetEntitiesByClass(sEntity)))
        end
    else
        aEntities = System.GetEntitiesByClass(sClass)
    end

    ----------
    if (not isArray(aEntities)) then
        return {} end

    ----------
    if (sMember) then
        aEntities = table.iselect(aEntities, function(v)
            local bOk = (not isNull(v[sMember]))
            return bOk
        end)
    end

    ----------
    if (isFunc(fPred)) then
        aEntities = table.iselect(aEntities, fPred)
    end

    ----------
    return aEntities
end