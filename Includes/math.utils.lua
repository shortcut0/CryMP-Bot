--=====================================================
-- CopyRight (c) R 2022-2203
--
-- Random (sometimes) useful string utils for lua
--
--=====================================================

-------------------
mathutils = {
	version = "0.1",
	author = "shortcut0",
	description = "all kinds of utiliy functions that might come in handy"
}

---------------------------
math.INF = (1 / 0)

---------------------------
-- math.t

math.t = tonumber;

---------------------------
-- math.isnumber

math.isnumber = function(i)
	return type(i) == "number"
end

---------------------------
-- math.fix

math.fix = function(i)
	if (i == math.INF or (i == 1 / 0) or tostring(i) == "inf") then
		i = 0
	end
	return i
end

---------------------------
-- math.div

math.div = function(i, d)
	if (i == 0 and d == 0) then
		return 0 
	elseif (i == 0) then
		return 0 
	elseif (d == 0) then
		return i end
		
	return i / d
end

---------------------------
-- math.round

math.round = function(i)
	return (i >= 0 and math.floor(i + 0.5) or math.ceil(i - 0.5))
end

---------------------------
-- math.fits

math.fits = function(target, number)
	local t = math.t;
	local f = string.gsub(target / number, "%.(%d+)$", "");
	local _ = t(f:sub(1, 1));
	if (not _ or _ < 1 or f:find("e")) then
		return 0, target;
	end;
	f = t(f);
	local r = target;
	if (f > 0) then
		r = r - (number * f);
	end;
	return (tonumber(string.format("%0.0f", f)) or 0), r; 
end;

---------------------------
-- math.loopindex

math.loopindex = function(num, target)
	local f = num / target
	if (target > num or f < 1) then
		return { 0, num }
	end
	local fits = string.gsub(f, "%.(.*)", "")
	local rem = num - (fits * target)
	return { fits, rem }
end;

---------------------------
-- math.calctime

math.calctime = function(s)
	local fits = math.fits;
	local c, s = fits(s, 86400 * 365 * 100);
	local y, s = fits(s, 86400 * 365);
	local d, s = fits(s, 86400);
	local h, s = fits(s, 3600);
	local m, s = fits(s, 60);
	s = math.fits(math.t(s), 1);
	if (y > 0 and y < 10) then 
		y = "0" .. y; 
	end;
	if (c > 0 and c < 10) then 
		c = "0" .. c; 
	end;
	if (m < 10) then m = "0" .. m; end;
	if (h < 10) then h = "0" .. h; end;
	if (d < 10) then d = "0" .. d; end;
	if (s < 10) then s = "0" .. s; end;
	return (math.t(c) > 0 and (c .. "c: ") or "") .. (math.t(y) > 0 and (y .. "y: ") or "") .. d .. "d: " .. h .. "h: " .. m .. "m: " .. s .. "s";
end

---------------------------
-- math.increase

math.increase = function(hVar, iAdd)
	return (checkNumber(hVar, 0) + checkNumber(iAdd, 0))
end

---------------------------
-- math.positive

math.positive = function(iNum)
	if (iNum < 0) then
		return (iNum * -1)
	end
	return iNum
end

---------------------------
-- math.negative

math.negative = function(iNum)
	if (iNum > 0) then
		return (iNum * -1)
	end
	return iNum
end

---------------------------
-- math.decrease

math.decrease = function(hVar, iRem)
	return (checkNumber(hVar, 0) - checkNumber(iRem, 0))
end

---------------------------
-- math.maxex

math.maxex = function(iNum, iMax)
	if (iNum > iMax) then
		return iMax
	end
	return iNum
end

---------------------------
-- math.minex

math.minex = function(iNum, iMin)
	if (iNum < iMin) then
		return iMin
	end
	return iNum
end

---------------------------
-- math.limit

math.limit = function(iNum, iMin, iMax)
	local iNew = iNum
	if (isNumber(iMin)) then
		iNew = math.minex(iNew, iMin)
	end
	if (isNumber(iMax)) then
		iNew = math.maxex(iNew, iMax)
	end
	return iNew
end

---------------------------
-- math.frandom

math.frandom = function(min, max)
	return min + math.random() * (max - min)
end

-------------------
mathutils.t = math.t
mathutils.div = math.div
mathutils.fits = math.fits
mathutils.calctime = math.calctime
mathutils.isnumber = math.isnumber
mathutils.maxex = math.maxex
mathutils.minex = math.minex
mathutils.limit = math.limit
mathutils.frandom = math.frandom

-------------------
return mathutils