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

timer.new = function()
	
	-----------
	local n = {}
	n.timer = timer.init()
	n.expired = function(i)
		return (timer.expired(n.timer, i))
	end

	-----------
	return n
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