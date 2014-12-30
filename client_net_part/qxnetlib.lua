if not qxnetlib then
	qxnetlib = {};
	require("framework.api.EventProtocol").extend(qxnetlib);
	qxnetlib._host = "127.0.0.1";
	qxnetlib._port = 7000;
	qxnetlib._tcp = nil;
	qxnetlib._failReConnectTime = 0;	--设置重连的计划时间，如果为0则不需要重连，单位为s, ms = s / 1000
	qxnetlib._recvScheduler = nil;	--接收数据的桢事件
	qxnetlib._reConnectScheduler = nil;	--重连事件
	qxnetlib.EVENT_SERVER_CONNECTED = "EVENT_SERVER_CONNECTED";	--连接成功的事件
	qxnetlib.EVENT_SERVER_CONNECT_FAIL = "EVENT_SERVER_CONNECT_FAIL";	--连接失败的事件
	qxnetlib.EVENT_SOCKET_CLOSED = "EVENT_SOCKET_CLOSED";	--连接断开的事件
	qxnetlib.EVENT_SOCKET_REVC_DATA = "EVENT_SOCKET_REVC_DATA";	--接收到数据的事件
	qxnetlib._recvDataCash = {};	--缓存数据块
end
local scheduler = require("framework.scheduler");
local socket = require("socket");
local qxpacket = require("net.qxpacket");

qxnetlib.connectServer = function(host, port, failReConnectTime)
	if host then qxnetlib._host = host; end
	if port then qxnetlib._port = port; end
	if failReConnectTime then qxnetlib._failReConnectTime = failReConnectTime; end
	qxnetlib._tryConnectServer();
end

qxnetlib._tryConnectServer = function()
	if not qxnetlib._tcp then
		qxnetlib._tcp = socket.tcp();
		qxnetlib._tcp:settimeout(0);
	end

	if qxnetlib._doConnect() then
		--连接成功，进入循环接收信息状态
		qxnetlib._setRecvCallBackInFrame();
	else		
		qxnetlib:dispatchEvent({name = qxnetlib.EVENT_SERVER_CONNECT_FAIL, isReConnect = qxnetlib._failReConnectTime > 0 and true or false});	--抛出连接失败的事件
		if qxnetlib._failReConnectTime > 0 then
			--连接失败，设置重连计划
			qxnetlib._reConnectServer();
		end
	end
end

qxnetlib._reConnectServer = function()
	if qxnetlib._reConnectScheduler then
		scheduler.unscheduleGlobal(qxnetlib._reConnectScheduler);
		qxnetlib._reConnectScheduler = nil;
	end
	qxnetlib._reConnectScheduler = scheduler.performWithDelayGlobal(function()
		qxnetlib._tryConnectServer();
	end, qxnetlib._failReConnectTime);
end

qxnetlib._doConnect = function()
	local succ, status = qxnetlib._tcp:connect(qxnetlib._host, qxnetlib._port);
	if succ == 1 or status == "already connected" then
		return true;
	end
	return false;
end

--桢函数
qxnetlib._onRecvCallBack = function()
	local body, status, partial = qxnetlib._tcp:receive("*a");
	if status == "closed" or status == "Socket is not connected" then
		--连接断开了
		qxnetlib._onClose();
		if qxnetlib._failReConnectTime > 0 then	--尝试重连
			qxnetlib._tryConnectServer();
		end
		return;
	end
	if (body and body:len() == 0) or (partial and partial:len() == 0) then
		--正常情况
		return;
	end
	--接收到数据，可能是数据库的片段
	if body and partial then body = body .. partial; end
	--print(body, partial, partial:len())
	table.insert(qxnetlib._recvDataCash, partial or body);
	qxnetlib._onRecvData();
end

--处理接收到的数据缓存
qxnetlib._onRecvData = function()
	if #qxnetlib._recvDataCash < 1 then
		return;
	end
	local recvStr = table.concat(qxnetlib._recvDataCash);
	local _, recvLen = string.unpack(recvStr:sub(1, 4), "=i");
	--TODO处理recvLen读出来是个负数的问题
	--print("recvLen:", recvLen, recvStr:len())
	if recvLen > recvStr:len() then
		return;	--还没接收完成
	end
	local recvDataStr = recvStr:sub(1, recvLen);
	local leftDataStr = recvStr:sub(recvLen + 1, #recvStr);
	qxnetlib._recvDataCash = {};
	if leftDataStr and tostring(leftDataStr) ~= "" then
		table.insert(qxnetlib._recvDataCash, leftDataStr);
	end
	--qxnetlib:dispatchEvent({name = qxnetlib.EVENT_SOCKET_REVC_DATA, data = recvDataStr});	--将数据抛出去
	local buff = qxpacket.new();
	buff:setPack(recvDataStr);
	buff:readInt();	--先将其往前移四位，数据长度，应用层不需要知道
	local head = buff:readString();	--读出协议头
	if head == "op_client" then 
		netlib.onRecvBuff(buff);
	end 
	buff = nil;

	--检查包里是否还有数据
	if #qxnetlib._recvDataCash > 0 then		
		qxnetlib._onRecvData();
	end
end

qxnetlib._setRecvCallBackInFrame = function()
	--连接成功了，需要设置一个检查接收数据包的桢函数
	qxnetlib:dispatchEvent({name = qxnetlib.EVENT_SERVER_CONNECTED});	--抛出连接成功的事件
	if qxnetlib._recvScheduler then	--清除旧值
		scheduler.unscheduleGlobal(qxnetlib._recvScheduler);
		qxnetlib._recvScheduler = nil;
	end
	qxnetlib._recvScheduler = scheduler.scheduleGlobal(qxnetlib._onRecvCallBack, 0.1);
end

qxnetlib._onClose = function()
	if qxnetlib._tcp then
		qxnetlib._tcp:close();
		qxnetlib._tcp = nil;
	end
	if qxnetlib._recvScheduler then
		scheduler.unscheduleGlobal(qxnetlib._recvScheduler);
		qxnetlib._recvScheduler = nil;
	end
	if qxnetlib._reConnectScheduler then
		scheduler.unscheduleGlobal(qxnetlib._reConnectScheduler);
		qxnetlib._reConnectScheduler = nil;
	end	

	qxnetlib:removeAllEventListenersForEvent(qxnetlib.EVENT_SERVER_CONNECTED);
	qxnetlib:removeAllEventListenersForEvent(qxnetlib.EVENT_SERVER_CONNECT_FAIL);
	qxnetlib:removeAllEventListenersForEvent(qxnetlib.EVENT_SOCKET_REVC_DATA);
	qxnetlib:dispatchEvent({name = qxnetlib.EVENT_SOCKET_CLOSED});
	qxnetlib:removeAllEventListenersForEvent(qxnetlib.EVENT_SOCKET_CLOSED);
end

qxnetlib.disConnection = function()
	qxnetlib._onClose()
end 


cmdlib = {};
cmdlib.cmdHandler = {};
cmdlib.regCmd = function(cmd, callback)
	assert(cmd);
	assert(callback);
--    print(cmdlib.cmdHandler[cmd])
	--assert(not cmdlib.cmdHandler[cmd], tostring(cmd) .. "exists");
    cmdlib.cmdHandler[cmd] = function(buff)
        callback(buff);
    end
end

netlib = {};
netlib.send = function(sendBuffFunc)
	assert(qxnetlib._tcp, "不存在连接实例");
	local buff = qxpacket.new();
	buff:setPos(5);
	buff:writeString("op_client");	--协议头
	sendBuffFunc(buff);
	buff:setPackSize(buff:getLen());
	qxnetlib._tcp:send(buff:getPack());
	buff = nil;
end

netlib.onRecvBuff = function(buff)
	local cmd = buff:readString();
	--print("收到协议：：：：", cmd)
	if cmdlib.cmdHandler[cmd] then
		local ret, errorInfo = pcall(cmdlib.cmdHandler[cmd], buff);
		if not ret then
			print("[协议名：" .. tostring(cmd) .. "]" .. tostring(errorInfo) .. debug.traceback());
		end
	else
		print("未注册的协议：" .. cmd);
	end
end



--[[
netlib.send(function(buff)
	buff:writeString("lo");
	buff:writeString("this is client");
	buff:writeByte(1);
	buff:writeInt(-10);
	buff:writeNumber(0.56);
end);

function onData(buff)	
	print(buff:readByte())
	print(buff:readString());
	print(buff:readByte())
	print(buff:readInt())
	print(buff:readNumber());
end
cmdlib.regCmd("recvServer", onData);
]]
------------------------------------

