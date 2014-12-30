-- 时间相关基本操作
timelib = timelib or 
{
	timeline  = {},
	time = 0,
	lasttime = 0,
	gridlen = 100,
};

--服务器时间
server = {};
server.mstime = 0;

server.mstime = cpp_getServerTime();

--入口
timelib.ontimecheck = function()
	timelib.time = math.ceil(server.mstime / timelib.gridlen)
	if timelib.lasttime ~= 0 and timelib.lasttime < timelib.time then
		for i = timelib.lasttime, timelib.time do
			if timelib.timeline[i] then
				for j = 1, #timelib.timeline[i] do
					xpcall(timelib.timeline[i][j], throw) 
				end
				timelib.timeline[i] = nil
			end
		end
	end
	timelib.lasttime = timelib.time
end

timelib.createplan = function(callback, delayMS)
    local delay = delayMS;
	assert(server.mstime > 0, "timelib have not init!!!!!!!!");
	assert(type(callback) == "function")
	assert(type(delay) == "number" and delay > 0)
    delay = math.ceil(delay / timelib.gridlen)
	local raise_time = timelib.time + delay
	if not timelib.timeline[raise_time] then
		timelib.timeline[raise_time] = {}
	end
	table.insert(timelib.timeline[raise_time], callback)
	local inx = #timelib.timeline[raise_time]

	local cancel = function()
		if timelib.timeline[raise_time] then
			timelib.timeline[raise_time][inx] = NULL_FUNC
        end
	end

	return
	{
		cancel = cancel,
		run = function()
			callback()
			cancel()
		end,
		getlefttime = function()
			return (raise_time - timelib.time) * timelib.gridlen
		end
	}
end

--lua时间转换为数据库时间格式
timelib.lua_to_db_time = function(lua_time)
	if type(lua_time) ~= "number" then
		error("lua_to_db_time传递了错误的时间格式")
		return "1970-1-1 0:0:0"
	end
    return os.date("%Y-%m-%d %X", lua_time)
end

--数据库时间转换为lua时间格式
timelib.db_to_lua_time = function(db_time)
	local time = {}
	for i in string.gmatch(db_time, "%d+") do
		table.insert(time, i)
	end
	local lua_time = os.time{year = time[1], month = time[2], day = time[3], hour = time[4], min = time[5], sec = time[6]}
	return lua_time
end

--返回一个空table,和普通table不同的是, 这个table的元素会自动超时并删除 seconds传入超时时间 (删除时机是增加新元素的时候)
timelib.newTimeoutTable = function(seconds, callback_timeout)
	local nseconds = seconds
	local ret = {}
	local data = {}
	local m = {}
	m.__index = function(tbl, key)
		local v = data[key]
		if not v then return end
		return v.value;
	end
	m.__newindex = function(tbl, key, value)
		data[key] =
		{
			["value"] = value,
			["del_plan"] = timelib.createplan(function()
				if callback_timeout ~= nil then
					xpcall(function() callback_timeout(value) end, throw)
				end
				data[key] = nil
			end, nseconds),
		}
	end
	ret.delItem = function(key)
		if data[key] then
			data[key].del_plan.cancel()
			data[key] = nil
		end
	end
	ret.showCount = function()
		local c = 0
		for k, v in pairs(data) do
			c = c + 1
		end
		TraceError(c)
    end
	setmetatable(ret, m)
	return ret
end

--是否在某天0点之前
timelib.is_before_today = function(time)
    local tableTime = os.date("*t",os.time())
    local endtime = os.time{year = tableTime.year, month = tableTime.month, day = tableTime.day, hour = 0}
    if time < endtime then
        return true, endtime
    else
        return false, endtime
    end
end

--得到某天0点的秒数
timelib.get_today_zero_sec = function(time)
    local tableTime = os.date("*t",time)
    local endtime = os.time{year = tableTime.year, month = tableTime.month, day = tableTime.day, hour = 0}
    return endtime
end

--检测两个日期是否是同一天
timelib.check2day_is_sameday = function(time1, time2)
	local tableTime1 = os.date("*t",time1)
	local tableTime2 = os.date("*t",time2)

	if tableTime1.year == tableTime2.year and tableTime1.month == tableTime2.month and tableTime1.day == tableTime2.day then
		return 1
	else
		return 0
	end
end
timelib.check2day_is_sameweek = function(time1,time2)
	local week1 = timelib.getRealWeekDay(time1)
	local week2 = timelib.getRealWeekDay(time2)
	if week1 == week2 then return 1 else return 0 end
end

--根据日期得到真正的周X
timelib.getRealWeekDay = function(time)
	local tableTime = os.date("*t", time)
	local usWDay = tableTime.wday
	local zhWday = 0
	if usWDay == 1 then
		zhWday = 7
	else
		zhWday = usWDay - 1
	end

	return zhWday
end
--得到现在是几号
timelib.getJihaoByTime = function(time)
	local tableTime = os.date("*t", time)
	return tableTime.day
end 

--根据日期得到月末的时间
timelib.getMonthEndDataStr = function(time)
	local tableTime = os.date("*t", time)
	local year = tableTime.year
	local month = tableTime.month
	local day = 1
	if month == 2 then
		day = year % 4 == 0 and 29 or 28
	else
		local list = {1,3,5,7,8,10,12}
		local isfind = 0
		for k,v in pairs(list) do
			if v == month then
				isfind = 1
				break
			end
		end

		day = isfind == 1 and 31 or 30
	end
	

	return string.format("%d-%d-%d", year, month, day)
end

