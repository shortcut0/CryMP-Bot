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
-- math.t

math.t = tonumber;

---------------------------
-- math.isnumber

math.isnumber = function(i)
	return type(i) == "number"
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

-------------------
mathutils.t = math.t
mathutils.div = math.div
mathutils.fits = math.fits
mathutils.calctime = math.calctime
mathutils.isnumber = math.isnumber

-------------------
return mathutils