--=====================================================
-- CopyRight (c) R 2022-2203
--
-- Random (sometimes) useful timer utils for lua
--
--=====================================================

-------------------
timer = {
	version = "1.0",
	author = "shortcut0",
	description = "all kinds of timer utility functions that might come in handy"
}

---------------------------
-- luautils.new

timer.new = function(expiry)

	-----------
	local timer = timer

	local hNew = {}
	hNew.created = timer.init()
	hNew.timer = timer.init()
	hNew.expiry = expiry

	--------
	hNew.setexpiry = function(i)
		if (isNumber(i)) then
			hNew.expiry = i
		end
	end
	--------
	hNew.refresh = function(i)
		hNew.timer = timer.init()
		hNew.expiry = checkVar(i, hNew.expiry)
	end
	--------
	hNew.expired = function(i)
		return (timer.expired(hNew.timer, checkNumber(i, hNew.expiry)))
	end
	--------
	hNew.diff_t = function(i) -- diff since creation
		return (timer.diff(hNew.created))
	end

	--------
	hNew.diff = function(i) -- diff since refresh (or creation)
		return (timer.diff(hNew.timer))
	end
	hNew.diff_refresh = function(i)
		local diff = (timer.diff(hNew.timer))
		hNew.refresh()
		return (diff)
	end

	-----------
	return hNew
end

---------------------------
-- luautils.init

timer.init = function()
	return (os.clock())
end

---------------------------
-- luautils.destroy

timer.destroy = function(hTimer)
	hTimer = nil
	return (nil)
end

---------------------------
-- timer.diff

timer.diff = function(hTimer)
	return (os.clock() - hTimer)
end

---------------------------
-- timer.check

timer.expired = function(hTimer, iTime)

	-----------
	if (not isNumber(hTimer)) then
		return true end
		
	-----------
	if (not isNumber(iTime)) then
		return true end
	
	-----------
	return (timer.diff(hTimer) >= iTime)
end

---------------------------
-- timer.sleep

timer.sleep = function(iMs)

	-----------
	if (not isNumber(iMs)) then
		return end

	-----------
	local iMs = (iMs / 1000)

	-----------
	local hSleepStart = timer.init()
	repeat
		-- sleep well <3
	until (timer.expired(hSleepStart, iMs))
end

---------------------------
-- timer.sleep_call

timer.sleep_call = function(iMs, fCall, ...)

	-----------
	if (not fCall) then
		return timer.sleep(iMs) end

	-----------
	if (not isNumber(iMs)) then
		return end

	-----------
	local iMs = (iMs / 1000)
	
	-----------
	local hSleepStart = timer.init()
	repeat
		-- sleep well <3
	until ((iMs ~= -1 and (timer.expired(hSleepStart, iMs))) or (fCall(...) == true))
end


-------------------
timernew = timer.new
timerinit = timer.init
timerdestroy = timer.destroy
timerdiff = timer.diff
timerexpired = timer.expired
sleep = timer.sleep
sleepCall = timer.sleep_call

-------------------
return timer