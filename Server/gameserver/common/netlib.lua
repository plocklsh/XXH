local qxpacket = require("common.qxpacket");
require("common.json");
netlib = netlib or
{
	_recvDataCash = {},
	ctrl_code_key = "",	--生成一个可变的验证码，提高系统内的协议安全性
	php_code_key = "kpgdakjg4546joiiru2&*%&%&r32",	--与php之间的通信key
	maxRecvSize = 1024 * 500,	--接收的数据包最大值500K
};

cmdlib = {};
cmdlib.cmdHandler = {};
cmdlib.regCmd = function(cmd, callback)
	assert(cmd);
	assert(callback);
	assert(not cmdlib.cmdHandler[cmd], tostring(cmd) .. " exists");
    cmdlib.cmdHandler[cmd] = function(buff)
        callback(buff);
    end
end
cmdlib.severCmdHandler = {};
cmdlib.regSeverCmd = function(cmd, callback)
	assert(cmd);
	assert(callback);
	assert(not cmdlib.severCmdHandler[cmd], tostring(cmd) .. " exists");
    cmdlib.severCmdHandler[cmd] = function(buff)
        callback(buff);
    end
end
cmdlib.phpCmdHandle = {};
cmdlib.regPhpCmd = function(cmd, callback)
	assert(cmd);
	assert(callback);
	assert(not cmdlib.phpCmdHandle[cmd], tostring(cmd) .. " exists");
	cmdlib.phpCmdHandle[cmd] = function(session, buff)
		return callback(session, buff);
	end
end

netlib.clearRecvDataCash = function(session)
	if netlib._recvDataCash[session] then
		netlib._recvDataCash[session] = nil;
	end
end

netlib.onRecvData = function(data, session, ip, port)
	if not netlib._recvDataCash[session] then
		netlib._recvDataCash[session] = {};
	end
	table.insert(netlib._recvDataCash[session], data);
	for i=1, 1000 do	--最多循环1000次，假设他有1000个数据包同时发了过来，一般不会出现这种情况
		if #netlib._recvDataCash[session] < 1 then
			break;
		end
		local recvStr = table.concat(netlib._recvDataCash[session]);
		if recvStr:len() < 4 then
			print("recv data len less than 4, len=" .. tostring(recvStr:len()), "ip=" .. tostring(ip), "port=" .. tostring(port), "session=" .. tostring(session));
			return;
		end
		local _, recvLen = string.unpack(recvStr:sub(1, 4), "=i");
		if recvLen < 1 then
			print("recv data recvlen less than 1, len=" .. tostring(recvLen), "ip=" .. tostring(ip), "port=" .. tostring(port), "session=" .. tostring(session));
			return;
		end
		--判断数据包过大或小于0的情况 断开链接
		if recvLen > netlib.maxRecvSize or recvStr:len() > netlib.maxRecvSize then
			print("recv data recvlen more than " .. tostring(netlib.maxRecvSize) .. ", len=" .. tostring(recvLen) .. ", datalen=" .. tostring(recvStr:len()), "ip=" .. tostring(ip), "port=" .. tostring(port), "session=" .. tostring(session));
			cpp_closeClientConn(session);
			return;
		end
		if recvLen > recvStr:len() then
			return;	--还没接收完成
		end	
		local recvDataStr = recvStr:sub(1, recvLen);
		local leftDataStr = recvStr:sub(recvLen + 1, #recvStr);
		netlib._recvDataCash[session] = {};
		if leftDataStr and tostring(leftDataStr) ~= "" then
			table.insert(netlib._recvDataCash[session], leftDataStr);
		end
		local buff = qxpacket.new();
		buff:setIp(ip);
		buff:setPort(port);
		buff:setSession(session);
		buff:setPack(recvDataStr);
		buff:readInt();	--先将其往前移四位，数据长度，应用层不需要知道

		local head = buff:readString();
		--print("head======" .. head);
		if head == "op_sever" then 
			netlib.onRecvServerBuff(buff);
		elseif head == "op_client" then
			netlib.onRecvBuff(buff);
		elseif head == "op_php" then
			netlib.onRecvPhpBuff(buff);
		elseif head == "&$@#" and buff:ip() == "127.0.0.1" then	--系统内协议
			local ctrl_code_key = buff:readString();
			--print(ctrl_code_key)
			if ctrl_code_key == netlib.ctrl_code_key then
				local ctrl_code = buff:readInt();
				--print("ctrl_code:" .. tostring(ctrl_code));
				if ctrl_code == 1 then
					cpp_closeServer();
				elseif ctrl_code == 0 then
					cpp_reloadScript();
				elseif ctrl_code == 2 then
					local debugStr = buff:readString();
					if debugStr then
						local doDebugF = loadstring(debugStr);
						if doDebugF then doDebugF(); end
					end
				end
			else
				print("ctrl_code_key wrong!!!! ctrl_code_key=" .. tostring(ctrl_code_key), "ip=" .. tostring(ip), "port=" .. tostring(port), "session=" .. tostring(session));
			end
		end
		
		buff = nil;	
	end
end

netlib.onRecvBuff = function(buff)
	local cmd = buff:readString();
	if cmdlib.cmdHandler[cmd] then		
		local ret, errorInfo = pcall(cmdlib.cmdHandler[cmd], buff);
		if not ret then
			print(_U"[协议名：" .. tostring(cmd) .. "]" .. tostring(errorInfo) .. debug.traceback());
		end
	else
		TraceError(_U"未注册的client协议：" .. tostringex(cmd));
	end
end

netlib.onRecvServerBuff = function(buff)
	local cmd = buff:readString();
	if cmdlib.severCmdHandler[cmd] then
		local ret, errorInfo = pcall(cmdlib.severCmdHandler[cmd], buff);
		if not ret then
			print(_U"[协议名：" .. tostring(cmd) .. "]," .. tostring(errorInfo) .. debug.traceback());
		end
	else
		TraceError(_U"未注册的server协议：" .. tostringex(cmd));
	end
end

netlib.onRecvPhpBuff = function(buff)
	local key = buff:readString();
	local data = buff:readString();
	--校验通信码
	local md5_str = md5(data .. netlib.php_code_key);
	if key ~= md5_str then
		--校验码不对，自己玩蛋去吧!
		cpp_closeClientConn(buff:session());
		TraceError(_U"php校验码不对啊，别乱发包好不好!!!" .. " " .. debug.traceback());
		return;
	end
	local decode_data = json.decode(data);
	local cmd = decode_data.cmd;
	if cmdlib.phpCmdHandle[cmd] then
		local ret, ret_data = cmdlib.phpCmdHandle[cmd](buff:session(), decode_data.data);

		if ret then	--假如存在返回值，则需要立即执行返回
			local send_str = json.encode({ret, ret_data or {}});
			--立马返回给php		
			netlib.onSendBuff(function(send_buff)
				send_buff:writeString(send_str);
			end, buff:session());
			timelib.createplan(function()
				--不好意思，我要先断开连接了
				cpp_closeClientConn(buff:session());
			end, 2000);
		end
	else
		timelib.createplan(function()
			cpp_closeClientConn(buff:session());
		end, 2000);
		TraceError(_U"未注册的php协议：" .. tostringex(cmd));			
	end
end


netlib.onSendBuff = function(sendBuffFunc, session, op)
	if not op then op = 1; end
	assert(op == 1 or op == 0);
	assert(session);
	assert(sendBuffFunc);
	local buff = qxpacket.new();
	buff:setPos(5);
	if op == 1 then
		buff:writeString("op_client");	--协议头
	elseif op == 0 then
		buff:writeString("op_sever");
	end 
	sendBuffFunc(buff);	
	buff:setPackSize(buff:getLen());
	cpp_onSend(buff:getLen(), buff:getPack(), session, op);	--最后一个参数为发送的对象 1=client 0=server
	buff = nil;
end

--生成一个执行系统命令的验证key
if netlib.ctrl_code_key == "" then
	math.randomseed(cpp_getServerTime());
	netlib.ctrl_code_key = md5(math.floor(math.random() * 999999) .. math.floor(math.random() * 999999) .. math.floor(math.random() * 999999));
	print("ctrl_code_key:" .. netlib.ctrl_code_key);
end
