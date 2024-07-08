--=====================================================
-- CopyRight (c) R 2024-2025
--
-- UTILITIES FOR THE CRYMP-BOT PROJECT
-- Credits: Sakura
--=====================================================

BotMath = {}

----------
INF = 1 / 0

----------
--- Dot
BotMath.Dot = function(self, a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z;
end

----------
--- Angle
BotMath.Angle = function(self, a, b)
    local dt = self:Dot(a, b)
    local ad = math.sqrt(self:Dot(a, a)) * math.sqrt(self:Dot(b, b))
    return math.acos(dt / ad) * 180 / math.pi;
end

----------
--- Lerp
BotMath.lerp = function(self, a, b, t)
    if type(a) == "table" and type(b) == "table" then
        if a.x and a.y and b.x and b.y then
            if a.z and b.z then return self:lerp3(a, b, t) end
            return self:lerp2(a, b, t)
        end
    end
    t = self:clamp(t, 0, 1)
    return a + t*(b-a)
end

----------
--- _Lerp
BotMath._lerp = function(self, a, b, t)
    return a + t*(b-a)
end

----------
--- Lerp2
BotMath.lerp2 = function(self, a, b, t)
    t = self:clamp(t, 0, 1)
    return { x = self:_lerp(a.x, b.x, t); y = self:_lerp(a.y, b.y, t); };
end

----------
--- Lerp3
BotMath.lerp3 = function(self, a, b, t)
    t = self:clamp(t, 0, 1)
    return { x = self:_lerp(a.x, b.x, t); y = self:_lerp(a.y, b.y, t); z = self:_lerp(a.z, b.z, t); };
end

----------
--- Clamp
BotMath.clamp = function(self, a, b, t)
    if a < b then return b end
    if a > t then return t end
    return a
end