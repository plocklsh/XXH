dofile("common/common.lua");
dofile("common/class.lua");
dofile("common/netlib.lua");
dofile("common/dblib.lua");
dofile("common/string.lua");
dofile("common/timelib.lua");

dofile("loginserver/lisnetlib.lua");

if not hasListenerPort then
	cpp_initListener(servercfg.host, servercfg.port);
	hasListenerPort = 1;
end

if servercfg.gls and not hasConnected then
	for _, glsinfo in pairs(servercfg.gls) do
		cpp_connectTo(glsinfo.sno, glsinfo.host, glsinfo.port);
	end
	hasConnected = 1;
end

function enterFrame()
end

--客户端连上来了
function lua_onconn(session)
	TraceError("session:" .. session)
end

--客户端断开连接了
function lua_oncloseconn(session)
	TraceError("session:" .. session .. "disconnect")
	cpp_closeClientConn(session)
end

--客户端完全断开连接了的回调
function lua_onFinalClosed(session)
	print("session:" .. session .. " final closed");

	--清除接收数据的缓存
	netlib.clearRecvDataCash(session);
end

--接收到客户端信息
function lua_onrecv(data, session, ip, port)
	--TraceError("len:" .. data:len())
	xpcall(function()
		netlib.onRecvData(data, session, ip, port);
	end, function()
		print("session=" .. tostring(session) .. ", ip=" .. tostring(ip) .. ", port=" .. tostring(port) .. "    " .. debug.traceback());
	end);
end

--调用cpp_closeClientConn(session)可以让客户端断开连接

--连接服务器成功
function lua_onconnserver(sno)
	TraceError("sno:" .. sno);
end

function lua_onServerClose()
	print "server close"

	--!!!!!!!!!!!!!!!!!此函数必须要在最后执行!!!!!!!!!!!!!!!!!!!!
	dblib.closeSever(cpp_closeServerFinal);
	--!!!!!!!!!!!!!!!!!此函数必须要在最后执行!!!!!!!!!!!!!!!!!!!!
end

--服务器时间检查相关
function lua_onTimeCheck(time)
	local mstime = time;
	if server.mstime > mstime then
		print(_U"时间错乱了吧？？？？？？！！！！！！time:" .. tostring(time) .. " lasttime:" .. server.mstime);
	else
		server.mstime = mstime;

		xpcall(function()
			timelib.ontimecheck();
		end, throw);
	end
end

--local sql = "select * from user";
--for i=1, 100 do
	--dblib.execsql(sql, function(dt) end, "dgacc");
--end
--cpp_onExcuteSql("127.0.0.1", "root", "12345678", "dgacc", 3306, sql, 1);

--[[
dblib.execsql("select 1", function(dt)
	if #dt == 1 then
		print(_U"数据库连接正常。");
	else
		print(_U"!!!!!!!数据库连接错误!!!!!!!" .. " " .. debug.traceback());
	end
end, "dgacc");
--]]

disable_global();

print "server init over"
