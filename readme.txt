有什么问题可以联系mike_just@163.com

/buildTool，存放luajit相关的，脚本编译时使用
/client_net_part，存放客户端的网络实现代码，作者之前是使用quick-cocos2d-x来做手游的，所以里面的实现有点依赖这个引擎(可以自己改为不依赖，比较简单)
/web_net_part，存放web端的一个网络实现代码，使用php实现
/newdbinfo，数据库创建相关
/GameServer，存放c/cpp/c#相关的代码
/Product，存放可运行文件，完整的服务器
/Server，存放服务器相关的脚本逻辑

服务器使用的是libuv，至于libuv相关的知识，自己百度去吧，服务器支持mysql数据和redis
每个服务器在/Product里面都有着xxx.exe.cfg的配置文件，这个是服务器脚本的入口文件，语法和lua一样。
若需要添加新的服务器，则复制/Product里的任意一个xx.exe文件，改个名字如aa.exe，然后添加aa.exe.cfg，需要外壳的话
则复制xxForm.exe，改个名字如aaForm.exe，然后添加aaForm.exe.xml（<processName>表示启动的程序，<port>要和aa.exe.cfg里的port一样，否则外壳起不了作用）

##########################################################################
【每个服务器的脚本中必须存在的函数】
lua_onsql(data, token);	//执行完sql后，C++执行的回调函数
lua_oncloseconn(session)	--客户端断开连接了
lua_onFinalClosed(session)	--客户端完全断开了连接
lua_onconn(session)	--客户端连上来了
lua_onrecv(data, session, ip, port)	--接收到客户端信息
lua_onServerClose()	--服务器关闭时执行的
lua_onTimeCheck(time)	--每桢执行，time为毫秒
enterFrame()	--每桢执行
##########################################################################


##########################################################################
【逻辑层可使用的cpp函数】
cpp_initListener(host, port)	--初始化服务器监听的端口相关
cpp_connectTo(sno, host, port)	--去连接其他的服务器
cpp_closeClientConn(session)	--断开session的连接
cpp_closeServer()	--关闭服务器
cpp_reloadScript()	--重载服务器脚本
##########################################################################