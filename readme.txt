��ʲô���������ϵmike_just@163.com

/buildTool�����luajit��صģ��ű�����ʱʹ��
/client_net_part����ſͻ��˵�����ʵ�ִ��룬����֮ǰ��ʹ��quick-cocos2d-x�������εģ����������ʵ���е������������(�����Լ���Ϊ���������Ƚϼ�)
/web_net_part�����web�˵�һ������ʵ�ִ��룬ʹ��phpʵ��
/newdbinfo�����ݿⴴ�����
/GameServer�����c/cpp/c#��صĴ���
/Product����ſ������ļ��������ķ�����
/Server����ŷ�������صĽű��߼�

������ʹ�õ���libuv������libuv��ص�֪ʶ���Լ��ٶ�ȥ�ɣ�������֧��mysql���ݺ�redis
ÿ����������/Product���涼����xxx.exe.cfg�������ļ�������Ƿ������ű�������ļ����﷨��luaһ����
����Ҫ����µķ�����������/Product�������һ��xx.exe�ļ����ĸ�������aa.exe��Ȼ�����aa.exe.cfg����Ҫ��ǵĻ�
����xxForm.exe���ĸ�������aaForm.exe��Ȼ�����aaForm.exe.xml��<processName>��ʾ�����ĳ���<port>Ҫ��aa.exe.cfg���portһ������������������ã�

##########################################################################
��ÿ���������Ľű��б�����ڵĺ�����
lua_onsql(data, token);	//ִ����sql��C++ִ�еĻص�����
lua_oncloseconn(session)	--�ͻ��˶Ͽ�������
lua_onFinalClosed(session)	--�ͻ�����ȫ�Ͽ�������
lua_onconn(session)	--�ͻ�����������
lua_onrecv(data, session, ip, port)	--���յ��ͻ�����Ϣ
lua_onServerClose()	--�������ر�ʱִ�е�
lua_onTimeCheck(time)	--ÿ��ִ�У�timeΪ����
enterFrame()	--ÿ��ִ��
##########################################################################


##########################################################################
���߼����ʹ�õ�cpp������
cpp_initListener(host, port)	--��ʼ�������������Ķ˿����
cpp_connectTo(sno, host, port)	--ȥ���������ķ�����
cpp_closeClientConn(session)	--�Ͽ�session������
cpp_closeServer()	--�رշ�����
cpp_reloadScript()	--���ط������ű�
##########################################################################