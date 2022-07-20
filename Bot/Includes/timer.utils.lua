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
-- luautils.init

timer.init = function()
	return (os.clock())
end

---------------------------
-- timer.diff

timer.diff = function(hTimer)
	return (os.clock() - hTimer)
end

---------------------------
-- timer.check

timer.expired = function(hTimer, iTime)
	if (not isNumber(hTimer)) then
		return true end
		
	if (not isNumber(iTime)) then
		return true end
	
	return (timer.diff(hTimer) >= iTime)
end

---------------------------
-- timer.sleep

timer.sleep = function(iMs)

	-----------
	local hSleepStart = timer.init()
	repeat
		-- sleep well <3
	until (timer.diff(hSleepStart) > iMs)
end

---------------------------
-- timer.sleep_call

timer.sleep_call = function(iMs, fCall, ...)

	-----------
	if (not fCall) then
		return timer.sleep(iMs) end
	
	-----------
	local hSleepStart = timer.init()
	repeat
		-- sleep well <3
	until ((iMs ~= -1 and (timer.diff(hSleepStart) > iMs)) or (fCall(...) == true))
end


-------------------
timerinit = timer.init
timerdiff = timer.diff
timerexpired = timer.expired
sleep = timer.sleep
sleepCall = timer.sleep_call

-------------------
return timer