
netlib.send = function(sendBuffFunc, session)
	netlib.onSendBuff(sendBuffFunc, session, 1);
end

netlib.sendGameServer = function(sendBuffFunc, sno)
	netlib.onSendBuff(sendBuffFunc, sno, 0);
end
