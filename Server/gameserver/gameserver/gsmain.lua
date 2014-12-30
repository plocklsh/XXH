--[[
                   _ooOoo_
                  o8888888o
                  88" . "88
                  (| -_- |)
                  O\  =  /O
               ____/`---'\____
             .'  \\|     |//  `.
            /  \\|||  :  |||//  \
           /  _||||| -:- |||||-  \
           |   | \\\  -  /// |   |
           | \_|  ''\---/''  |   |
           \  .-\__  `-`  ___/-. /
         ___`. .'  /--.--\  `. . __
      ."" '<  `.___\_<|>_/___.'  >'"".
     | | :  `- \`.;`\ _ /`;.`/ - ` : | |
     \  \ `-.   \_ __\ /__ _/   .-` /  /
======`-.____`-.___\_____/___.-`____.-'======
                   `=---='
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      佛祖保佑       永无BUG		永不修改
--]]

dofile("common/common.lua");
dofile("common/class.lua");
dofile("common/netlib.lua");
dofile("common/dblib.lua");
dofile("common/string.lua");
dofile("common/table.lua");
dofile("common/configlib.lua");
dofile("common/timelib.lua");
dofile("common/dirtyWordlib.lua");
dofile("common/loglib.lua");

dofile("gameserver/gsnetlib.lua");
dofile("gameserver/phplib.lua");	--php相关

--监听端口
if not hasListenerPort then
	cpp_initListener(servercfg.host, servercfg.port);
	hasListenerPort = 1;
end

if servercfg.ls and not hasConnected then
	for _, lsinfo in pairs(servercfg.ls) do
		cpp_connectTo(lsinfo.sno, lsinfo.host, lsinfo.port);
	end	
	hasConnected = 1;
end

--客户端连上来了
function lua_onconn(session)
	TraceError("session:" .. session)
end

--客户端断开连接了
function lua_oncloseconn(session)
	TraceError("session:" .. session .. "disconnect")	
	cpp_closeClientConn(session)--这里是真正断开
end

--客户端完全断开连接了的回调
function lua_onFinalClosed(session)
	print("session:" .. session .. " final closed");
	
	xpcall(function()		
		--清除接收数据的缓存
		netlib.clearRecvDataCash(session);
	end, throw);	
end

--接收到客户端信息
function lua_onrecv(data, session, ip, port)
	--TraceError("len:" .. data:len())
	netlib.onRecvData(data, session, ip, port);
end

--调用cpp_closeClientConn(session)可以让客户端断开连接

--调用此函数可连接到别的服务器
--cpp_connectTo(glsinfo.sno, glsinfo.host, glsinfo.port);

function lua_onServerClose()
	print "server close"

	loglib.forceCommit();	--强制写入所有的日志

	--!!!!!!!!!!!!!!!!!此函数必须要在最后执行!!!!!!!!!!!!!!!!!!!!
	dblib.closeSever(cpp_closeServerFinal);
	--!!!!!!!!!!!!!!!!!此函数必须要在最后执行!!!!!!!!!!!!!!!!!!!!
end

--连接服务器成功
function lua_onconnserver(sno)
	TraceError("sno:" .. sno);
end

function enterFrame()
	--print "lua enterFrame"	
	eventlib:dispatchEvent({name = "enterFrame"});
end

--[[
eventlib:addEventListener("enterFrame", function(et)
	TraceError("enterFrame")
end);
--]]

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

--[[
dblib.execsql("select 1", function(dt)
	if #dt == 1 then
		print(_U"数据库连接正常。");
		end, throw)
	else
		print(_U"!!!!!!!数据库连接错误!!!!!!!" .. " " .. debug.traceback());
	end
end, "dgacc");
--]]
--------------------------------------

disable_global();

print "server init over"
