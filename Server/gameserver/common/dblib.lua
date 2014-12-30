redis = require("..common.redis");
dblib = dblib or
{
	cbf = {},
	token = 0,
	_onservershutdowncbf = nil,	--用于处理服务器关闭
}

--执行了sql语后，C++回调函数
function lua_onsql(data, token)
	--TraceError(data);
	--TraceError("token=" .. token)
	if dblib.cbf[token] ~= nil then
		dblib.cbf[token](data);
	end
	dblib.cbf[token] = nil;

	if dblib._onservershutdowncbf and not next(dblib.cbf) then
		dblib._onservershutdowncbf();
		dblib._onservershutdowncbf = nil;
	end
end

function dblib.execsql(sql, callback, dbname)
	assert(sql and callback and dbname)
	assert(servercfg and servercfg["dbinfo"] and servercfg["dbinfo"][dbname]);
	
	dblib.token = dblib.token + 1;
	if dblib.token > 999999999 then
		dblib.token = 1;
	end

	dblib.cbf[dblib.token] = callback;
	local dbinfo = servercfg["dbinfo"][dbname];
	cpp_onExcuteSql(dbinfo["ip"], dbinfo["username"], dbinfo["password"], dbname, dbinfo["port"], sql, dblib.token);

	--onLuaCallCppDBMysql("127.0.0.1", "root", "12345678", "dgacc", 3306, "select * from user", 1);
end

function dblib.closeSever(cbf)
	if next(dblib.cbf) then	--存在回调函数，需要等待全部执行完成才能关服
		dblib._onservershutdowncbf = cbf;
	else
		cbf();	--直接执行
	end
end

--[[
function testRedis()	
	local client = redis.connect("127.0.0.1", 6379);
	local response = client:ping();
	print(response)
	client:set("usr:nrk", 10);
	client:set("usr:nobody", 5);
	local value = client:get("usr:nrk");
	print(value)
end
--]]
