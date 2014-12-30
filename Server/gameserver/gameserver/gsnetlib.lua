gsnetlib = gsnetlib or
{
};

netlib.send = function(sendBuffFunc, session)	
	netlib.onSendBuff(sendBuffFunc, session);	
end

netlib.sendLoginServer = function(sendBuffFunc, sno)
	netlib.onSendBuff(sendBuffFunc, sno, 0);
end