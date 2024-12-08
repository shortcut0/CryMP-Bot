--------------------------------------
--- File: RWITools.lua
---
--- Author: Marisa
---
--- Description: Ray World Intersection tools for the CryMP-Bot Project
---
--- TODO:
---     Move all RWI Related functions here!
---
--------------------------------------


-------------

ent_water = 200

-------------

RWI_FLAGS_NONE = 0x00 -- default
RWI_FLAGS_PIERCEABILITY0 = 0x01
RWI_FLAGS_FORCENOCOLL = 0x02 -- forced no_pierce collision
RWI_FLAGS_LAMTYPE = 0x03 -- lam collision
RWI_FLAGS_AMMOPIERCE0 = 0x04 -- bullet projectile like
RWI_FLAGS_AMMOPIERCE1 = 0x05 -- solid projectile like
RWI_FLAGS_PLAYERVIEWCOLL = 0x06 -- player view collision
RWI_FLAGS_AIVISIBILITY0 = 0x07 -- the same flags ai system uses for visibility
RWI_FLAGS_AIVISIBILITY1 = 0x08 -- flags and modified entitiy types (!) the ai system uses for visibility
RWI_FLAGS_AIVISIBILITY2 = 0x09 -- flags and modified entitiy types (!) the ai system uses for visibility

-------------

RWI_MAX_DISTANCE = BOT_RAYWORLD_MAXDIST
RWI_MAX_HITS = 10

-------------

RWI_GET_ALL = ent_all
RWI_GET_WATER = ent_water
RWI_GET_STATIC = (ent_all - ent_living - ent_rigid)
RWI_GET_PHYSICALIZED = (ent_all - ent_static)

-------------
RWITools = {}
RWI_HitTable = {}

-------------

RWI_GetDown = GetErrorDummy() -- Down Pos
RWI_GetPos = GetErrorDummy() -- Any Hit Pos
RWI_GetHit = GetErrorDummy() -- Any Hit
RWI_GetStaticHit = GetErrorDummy() -- Any Hit

RWI_Trace = GetErrorDummy() -- Trace check

RWI_Distance = GetErrorDummy() -- Hit Distance
RWI_DistanceCheck = GetErrorDummy() -- Check Hit Distance
RWI_Distance_Flags = GetErrorDummy() -- Check Hit Distance

-------------

RWI_LOG_PREFIX = "$9[$5RWITools$9] "

-------------

RWILog = function(sMsg, ...)
    SystemLog(string.formatex(RWI_LOG_PREFIX .. (sMsg or ""), ...))
end

-------------
--- Init
RWITools.Init = function(self)

    -- Log
    RWILog("Initializing..")
    RWILog("Registering functions..")

    -- Hits
    RWI_Hit = self.Do_Hit_Simple
    RWI_HitEx = self.Do_Hit

    -- Intersecting
    RWI_GetDown = self.GetDownPos
    RWI_GetPos = self.GetPos
    RWI_GetHit = self.GetHit
    RWI_GetStaticHit = self.RWI_GetHit_Static

    -- Custom
    RWI_GetHit_Flags = self.GetHit_Flags
    RWI_GetPos_Flags = self.GetPos_Flags

    -- Tracing
    RWI_Trace = self.GetTrace

    -- Distances
    RWI_Distance = self.GetDistance
    RWI_DistanceCheck = self.CheckDistance
    RWI_Distance_Flags = self.GetDistance_Flags

    -- Checks
    RWI_HitBig = self.CheckHitBig

    -- Log
    RWILog("Finished!")
end

-------------
--- Do_Hit_Simple
RWITools.Do_Hit_Simple = function(vSource, vDir, iDistance, bGetAll)

    local vDir_Scaled = vector.copy(vDir)
    if (vector.isnormalized(vDir_Scaled) or iDistance ~= nil) then
        vDir_Scaled = vector.scaleInPlace(vDir, RWITools.ValidateDistance((iDistance or RWI_MAX_DISTANCE)))
    end

    local iHits = Physics.RayWorldIntersection(vSource, vDir_Scaled, RWI_MAX_HITS, RWI_GET_ALL, g_localActorId, nil, RWI_HitTable, RWI_FLAGS_NONE)
    if (iHits > 0) then
        if (bGetAll) then
            return iHits, RWI_HitTable
        end
        return RWI_HitTable[1]
    end

    return
end

-------------
--- CheckHitBig
RWITools.CheckHitBig = function(iHits, aHits)

    if (iHits == nil or iHits < 1) then
        return false
    end

    local hEnt, aBBox
    local bIsBig = true
    for _, aHit in pairs(aHits) do
        hEnt = aHit.entity
        if (hEnt) then
            aBBox = { hEnt:GetLocalBBox() }
            if (vector.bbox_size(aBBox).z > 1.2) then
                bIsBig = false
            end
        end

        if (aHit.renderNode and vector.bbox_size((aHit.render_bbox or vector.bbox())).z > 0.5) then
            bIsBig = true
            break
        end
    end

    return bIsBig
end

-------------
--- Do_Hit
RWITools.Do_Hit = function(vSource, vDir, iDistance, iFlags, iEnts, bGetAll)

    local vDir_Scaled = vector.copy(vDir)
    if (vector.isnormalized(vDir_Scaled) or iDistance ~= nil) then
        vDir_Scaled = vector.scaleInPlace(vDir, RWITools.ValidateDistance((iDistance or RWI_MAX_DISTANCE)))
    end

    local iHits = Physics.RayWorldIntersection(vSource, vDir_Scaled, RWI_MAX_HITS, (iEnts or RWI_GET_ALL), g_localActorId, nil, RWI_HitTable, iFlags)
    if (iHits > 0) then
        if (bGetAll) then
            return iHits, RWI_HitTable
        end
        return RWI_HitTable[1]
    end

    return
end

-------------
--- GetTrace_Simple
RWITools.Do_Trace_Simple = function(vSource, vTarget)

   local bOk = Physics.RayTraceCheck(vSource, vTarget, NULL_ENTITY, NULL_ENTITY)
   return bOk
end

-------------
--- GetTrace_Simple
RWITools.Do_Trace = function(vSource, vTarget, nIgnore_1, nIgnore_2)

   local bOk = Physics.RayTraceCheck(vSource, vTarget, checkVar(nIgnore_1, NULL_ENTITY), checkVar(nIgnore_2, NULL_ENTITY))
    return bOk
end

-------------
--- GetDownPos
RWITools.GetDownPos = function(vSource)

    local aHit = RWITools.Do_Hit_Simple(vSource, vectors.down)
    if (aHit) then
        return aHit.pos
    end

    return nil
end

-------------
--- GetPos
RWITools.GetPos = function(vSource, vDir, iDistance)

    local aHit = RWITools.Do_Hit_Simple(vSource, vDir, iDistance)
    if (aHit) then
        return aHit.pos
    end

    return nil
end

-------------
--- GetPos
RWITools.GetPos_Flags = function(vSource, vDir, iDistance, iFlags, iEnts)

    local aHit = RWITools.Do_Hit(vSource, vDir, iDistance, iFlags, iEnts)
    if (aHit) then
        return aHit.pos
    end

    return nil
end

-------------
--- GetHit
RWITools.GetHit = function(vSource, vDir)

    local aHit = RWITools.Do_Hit_Simple(vSource, vDir)
    if (aHit) then
        return aHit
    end

    return nil
end

-------------
--- GetHit
RWITools.GetHit_Flags = function(vSource, vDir, iDistance, iFlags, iEnts)

    local aHit = RWITools.Do_Hit(vSource, vDir, iDistance, iFlags, iEnts)
    if (aHit) then
        return aHit
    end

    return nil
end

-------------
--- GetTrace
RWITools.RWI_GetHit_Static = function(vSource, vDir, iDistance, aStaticChecks, aMaterialChecks)

    local aHit = RWITools.Do_Hit_Simple(vSource, vDir, iDistance)
    if (aHit) then

        local sSurfaceName = System.GetSurfaceTypeNameById(aHit.surface or 0)
        local sStaticName = aHit.static_name

        if (aStaticChecks or aMaterialChecks) then
            local bOk = (table.contains((aStaticChecks or {}), sStaticName) or table.contains((aMaterialChecks or {}), sSurfaceName))
            return bOk
        end

        return aHit.static_name
    end

    return
end

-------------
--- Init
RWITools.GetDistance = function(vSource, vDir, iMaxDistance)

    local aHit = RWITools.Do_Hit_Simple(vSource, vDir, iMaxDistance)
    if (aHit) then
        BotMainLog("%f",aHit.dist)
        return aHit.dist
    end

    return nil
end

-------------
--- Init
RWITools.GetDistance_Flags = function(vSource, vDir, iDistance, iFlags, iEnts)

    local aHit = RWITools.Do_Hit(vSource, vDir, iDistance, iFlags, iEnts)
    if (aHit) then
        return aHit.dist
    end

    return nil
end

-------------
--- Init
RWITools.CheckDistance = function(vSource, vDir, iThreshold)

    local aHit = RWITools.Do_Hit_Simple(vSource, vDir, RWI_MAX_DISTANCE)
    if (aHit) then
        return (aHit.dist < iThreshold)
    end

    -- no hit
    return false
end

-------------
--- GetTrace
RWITools.GetTrace = function(vSource, vTarget)
    return RWITools.Do_Trace_Simple(vSource, vTarget)
end

-------------
--- Validate Distance
RWITools.ValidateDistance = function(iDistance)
    return (math.limit(iDistance, 0.01, RWI_MAX_DISTANCE))
end