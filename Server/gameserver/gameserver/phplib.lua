phplib = phplib or {};

phplib.send = function(session, data)
	local send_str = json.encode({data.ret, data.ret_data or {}});
	netlib.onSendBuff(function(buff)
		buff:writeString(send_str);
	end, session);

	--执行完成一定要断开
	timelib.createplan(function()
		cpp_closeClientConn(session);
	end, 2000);	
end

--[[
phplib.phpSocketTest = function(data)
	TraceError(data);
	return 1, {};
end
cmdlib.regPhpCmd("phpSocketTest", phplib.phpSocketTest);
--]]
