/*
	Author: limenghong

	GameServer.cpp : 定义控制台应用程序的入口点。
*/

#include "stdafx.h"
#include "uthash.h"
#include "utils.h"
#include <string>
using namespace std;
#include <sys/timeb.h>
#include "uv.h"
#include "LuaScript.h"
extern "C"
{
	#include "lpack.h"
	#include "md5.h"

	// socket
	#include "luasocket/luasocket.h"
	#include "luasocket/mime.h"
	#include "luasocket/socket_scripts.h"
}
#include "MysqlDB.h"
//#include "linked_list.h"

#include "GameServer.h"

const char* SEVERNAME;
static lua_State *g_luaHandel;
static uv_tcp_t g_tcpServer;
static uv_loop_t *g_loop;
//static uv_idle_t g_idler;
static uv_timer_t g_timer;
static int g_session = 1;
static P_CLIENTDATA g_clientDataList = NULL;
static P_SERVERDATA g_serverDataList = NULL;

int _tmain(int argc, _TCHAR* argv[])
{
	//SEVERNAME = getServerFileName();	//获取服务器的文件名，很重要，获取失败的话，后果很严重
	//const char *servername = getServerFileName();	
#if defined(_WIN32)
	char moduleFileName[MAX_PATH];
	GetModuleFileNameA(0, moduleFileName, MAX_PATH);	
	string sname(moduleFileName);
	size_t pos = sname.find_last_of("\\");
	sname = sname.substr(pos + 1, sname.length() - pos - 5);
	SEVERNAME = sname.c_str();
#else	
	std::string sname("GameServer");
	SEVERNAME = sname.c_str();
#endif

	g_session = 1;
	g_luaHandel = initLuaScript();
	ASSERT(g_luaHandel != NULL);

	//注册一批函数给lua使用
	luaopen_pack(g_luaHandel);	//lua pack
	/*#################luasokcet#################*/
	luaopen_socket_core(g_luaHandel);
	luaopen_mime_core(g_luaHandel);
	luaopen_socket_scripts(g_luaHandel);
	/*#################luasokcet#################*/
	lua_register(g_luaHandel, "md5", md5);	
	lua_register(g_luaHandel, "cpp_initListener", initListener);
	lua_register(g_luaHandel, "cpp_closeClientConn", cppCloseClientConn);
	lua_register(g_luaHandel, "cpp_closeServerConn", cppCloseServerConn);	
	lua_register(g_luaHandel, "cpp_onSend", onSend);	
	lua_register(g_luaHandel, "cpp_onExcuteSql", onExcuteSql);
	lua_register(g_luaHandel, "cpp_connectTo", connectTo);
	lua_register(g_luaHandel, "cpp_closeServer", closeServer);	
	lua_register(g_luaHandel, "cpp_closeServerFinal", closeServerFinal);
	lua_register(g_luaHandel, "cpp_reloadScript", reloadScript);
	lua_register(g_luaHandel, "cpp_getServerTime", _getServerTime);	
	lua_register(g_luaHandel, "_U", _U);	

	//注册lua print
	lua_pushcfunction(g_luaHandel, lua_print);
    lua_setglobal(g_luaHandel, "print");

	//启动消息循环
	g_loop = uv_default_loop();

	//执行并加载脚本文件
	ASSERT(loadLuaScript(g_luaHandel) == 0);

	//定义逻辑桢事件
	//uv_idle_init(g_loop, &g_idler);
	//uv_idle_start(&g_idler, enterFrame);

	uv_timer_init(g_loop, &g_timer);
	ASSERT(!uv_is_active((uv_handle_t*) &g_timer));
	ASSERT(!uv_is_closing((uv_handle_t*) &g_timer));
	uv_timer_start(&g_timer, enterFrame, 0, 1000 / 60);
	//定义逻辑桢事件
	
	log("服务器启动成功！！！！\n");

#if defined(_WIN32)
	if (SetConsoleCtrlHandler((PHANDLER_ROUTINE) ctrlHandler, TRUE))
	{
		uv_run(g_loop, UV_RUN_DEFAULT);	
	}
#else
	uv_run(g_loop, UV_RUN_DEFAULT);
#endif

	log("服务器运行结束！！！！\n");
	return 0;
}

#if defined(_WIN32)
BOOL ctrlHandler(DWORD fdwCtrlType)
{		
	if (fdwCtrlType == CTRL_C_EVENT || fdwCtrlType == CTRL_CLOSE_EVENT || fdwCtrlType == CTRL_BREAK_EVENT || fdwCtrlType == CTRL_LOGOFF_EVENT || fdwCtrlType == CTRL_SHUTDOWN_EVENT)
	{
		doCloseServer();
		return TRUE;
	}
	return FALSE;
}
#endif

static void enterFrame(uv_timer_t* handle)
{
	if (g_luaHandel != NULL)
	{
		lua_getglobal(g_luaHandel, "enterFrame");
		if (lua_pcall(g_luaHandel, 0, 0, 0) != 0)
		{
			//LOGF("Error:runing luafunction [enterFrame], %s\r\n", lua_tostring(g_luaHandel, -1));
			lua_error(g_luaHandel, lua_tostring(g_luaHandel, -1));
		}

		lua_getglobal(g_luaHandel, "lua_onTimeCheck");		
		uint64_t timevalue = getServerTime();
		lua_pushnumber(g_luaHandel, timevalue);
		if (lua_pcall(g_luaHandel, 1, 0, 0) != 0)
		{
			lua_error(g_luaHandel, lua_tostring(g_luaHandel, -1));
		}
	}
}

static int initListener(lua_State *L)
{
	ASSERT(2 == lua_gettop(L));
	const char *ip = lua_tostring(L, 1);
	int port = lua_tointeger(L, 2);

	struct sockaddr_in addr;
	int r;	
	ASSERT(0 == uv_ip4_addr(ip, port, &addr));
	r = uv_tcp_init(g_loop, &g_tcpServer);
	ASSERT(r == 0);
	r = uv_tcp_bind(&g_tcpServer, (const struct sockaddr*) &addr, 0);
	ASSERT(r == 0);
	r = uv_listen((uv_stream_t*)&g_tcpServer, SOMAXCONN, newClientConnection);
	ASSERT(r == 0);	
	return 1;
}

static int reloadScript(lua_State *L)
{
	log("#####################重新加载脚本文件开始###################\n");
	ASSERT(loadLuaScript(g_luaHandel) == 0);
	log("#####################重新加载脚本文件成功###################\n");
	return 1;
}

static int closeServer(lua_State *L)
{	
	doCloseServer();
	return 0;
}

static void doCloseServer()
{
	//通知lua服务器要关闭了
	if (g_luaHandel != NULL)
	{
		lua_getglobal(g_luaHandel, "lua_onServerClose");
		if (lua_pcall(g_luaHandel, 0, 0, 0) != 0)
		{
			//LOGF("Error:runing luafunction [lua_onconnserver], %s\r\n", lua_tostring(g_luaHandel, -1));
			lua_error(g_luaHandel, lua_tostring(g_luaHandel, -1));
		}
	}
	else
	{
		closeServerFinal(NULL);
	}
}

//关闭服务器终极函数，调用到这里，服务器就真的关闭了
static int closeServerFinal(lua_State *L)
{
	//uv_idle_stop(&g_idler);
	lua_close(g_luaHandel);
	uv_timer_stop(&g_timer);
	uv_stop(g_loop);
	g_loop = NULL;
	return 0;
}

//服务器启动的时候就应该去和其他服务器相连接所以直接用assert
static int connectTo(lua_State *L)
{
	ASSERT(3 == lua_gettop(L));
	ASSERT(lua_isnumber(L, 1) == 1);
	ASSERT(lua_isstring(L, 2) == 1);
	ASSERT(lua_isnumber(L, 3) == 1);
	int sno = lua_tointeger(L, 1);
	const char *ip = lua_tostring(L, 2);
	int port = lua_tointeger(L, 3);
	struct sockaddr_in addr;
	ASSERT(0 == uv_ip4_addr(ip, port, &addr));
	P_SERVERDATA serverData = (P_SERVERDATA) malloc(sizeof(SERVERDATA));
	ASSERT(serverData != NULL);	
	serverData->sno = sno;	//记录服务器编号
	//fprintf(stderr, "[%d %s %d]\n", sno, ip, port);
	strcpy_s(serverData->ip, ip);
	serverData->port = port;
	ASSERT(0 == uv_tcp_init(g_loop, &serverData->tcpHandle));
	int r;	
	//fprintf(stderr, "aaaaaaaaaaa\n");
	r = uv_tcp_connect(&serverData->connect_reqs, &serverData->tcpHandle, (const struct sockaddr*) &addr, connect_cb);
	//fprintf(stderr, "bbbbbbbbbbbbb\n");
	if (r != 0)
	{
		//连接失败了
		char logbuf[50];
		sprintf(logbuf, "服务器连接失败了[%s:%d]!!!!!!!\n", ip, port);
		log(logbuf);
		ASSERT(0);
		return 0;
	}
	return 1;
}
static void connect_cb(uv_connect_t* req, int status)
{
	//ASSERT(status == 0);
	SERVERDATA *serverData = NULL;
	serverData = container_of(req, SERVERDATA, connect_reqs);
	if (serverData == NULL)
	{
		log("服务器之间的连接出问题了，没有找到相关的服务器实例，一定是代码出bug了！！！！！！");
		ASSERT(0);
		return;
	}
	if (status != 0)
	{
		struct sockaddr_in addr;
		ASSERT(0 == uv_ip4_addr(serverData->ip, serverData->port, &addr));
		int r;
		r = uv_tcp_connect(&serverData->connect_reqs, &serverData->tcpHandle, (const struct sockaddr*) &addr, connect_cb);
		if (r != 0)
		{
			//连接失败了
			LOGF("服务器重新连接失败了[%s:%d]!!!!!!!\n", serverData->ip, serverData->port);
			ASSERT(0);
		}
		//连接失败，尝试重连
		return;
	}
	//fprintf(stderr, "[%s %d %d]\n", serverData->ip, serverData->port, serverData->sno);
	//放入服务器组列表里
	//INSERT_TO_LIST(g_serverDataList, serverData, m_prev, m_next);
	HASH_ADD_INT(g_serverDataList, sno, serverData);

	//通知lua已连接成功
	if (g_luaHandel != NULL)
	{
		lua_getglobal(g_luaHandel, "lua_onconnserver");
		lua_pushinteger(g_luaHandel, serverData->sno);
		if (lua_pcall(g_luaHandel, 1, 0, 0) != 0)
		{
			//LOGF("Error:runing luafunction [lua_onconnserver], %s\r\n", lua_tostring(g_luaHandel, -1));
			lua_error(g_luaHandel, lua_tostring(g_luaHandel, -1));
		}
	}

	ASSERT(uv_read_start((uv_stream_t*)&serverData->tcpHandle, alloc_cb, read_server_cb) == 0);
}

static void read_server_cb(uv_stream_t* stream, ssize_t nread, const uv_buf_t* buf)
{	
	SERVERDATA *serverData = NULL;
	serverData = container_of(stream, SERVERDATA, tcpHandle);
	if (serverData == NULL)
	{
		log("读取服务器数据的时候，没有找到相关的服务器实例，一定是代码出bug了！！！！！！");
		return;
	}	

	if (nread >= 0)
	{
		//直接扔给lua来处理
		if (g_luaHandel != NULL)
		{
			char bufStr[dMAX_SOCKET_RECV_BUFF];
			memcpy(&bufStr, buf->base, nread);
			lua_getglobal(g_luaHandel, "lua_onrecv");
			lua_pushlstring(g_luaHandel, bufStr, nread);
			lua_pushinteger(g_luaHandel, serverData->sno);	//记住此处为服务器编号，而非seesion
			lua_pushfstring(g_luaHandel, serverData->ip);
			lua_pushinteger(g_luaHandel, serverData->port);
			if (lua_pcall(g_luaHandel, 4, 0, 0) != 0)
			{
				//LOGF("Error:runing luafunction [lua_onrecv], %s\r\n", lua_tostring(g_luaHandel, -1));
				lua_error(g_luaHandel, lua_tostring(g_luaHandel, -1));
			}
			*bufStr = '\0';
		}
		return;
	}	

	//服务器崩了吗？？？？？？？？？？处理重连
	LOGF("服务器崩了吗？？？？？？？？？？[%d=%s:%d]\n", serverData->sno, serverData->ip, serverData->port);

	LOGF("正在死命地重连！！！！！[%d=%s:%d]\n", serverData->sno, serverData->ip, serverData->port);

	P_SERVERDATA reServerData = (P_SERVERDATA) malloc(sizeof(SERVERDATA));
	if (!reServerData) { log("memory is not enough!"); return; }
	reServerData->sno = serverData->sno;	//记录服务器编号
	strcpy_s(reServerData->ip, serverData->ip);
	reServerData->port = serverData->port;
	ASSERT(0 == uv_tcp_init(g_loop, &reServerData->tcpHandle));
	//将旧的连接干掉
	HASH_DEL(g_serverDataList, serverData);
	free(serverData);
	serverData = NULL;

	struct sockaddr_in addr;
	ASSERT(0 == uv_ip4_addr(reServerData->ip, reServerData->port, &addr));
	int r;
	r = uv_tcp_connect(&reServerData->connect_reqs, &reServerData->tcpHandle, (const struct sockaddr*) &addr, connect_cb);
	if (r != 0)
	{
		//连接失败了
		LOGF("服务器意外崩溃后，重新连接失败了[%s:%d]!!!!!!!\n", reServerData->ip, reServerData->port);
		ASSERT(0);
	}
}


static void newClientConnection(uv_stream_t* stream, int status)
{
	if (status != 0) return;
	if (stream != (uv_stream_t*) &g_tcpServer) return;
	if (g_session > 2147483645) return;	

	int r;
	P_CLIENTDATA clientData = (P_CLIENTDATA) malloc(sizeof(CLIENTDATA));
	if (clientData == NULL) { log("memory is not enough!"); return; }	//内存没了吧

	r = uv_tcp_init(stream->loop, &clientData->tcpHandle);
	if (r != 0) return;

	r = uv_accept(stream, (uv_stream_t*)&clientData->tcpHandle);
	if (r != 0) return;

	struct sockaddr_in sockname;
	int namelen;
	namelen = sizeof sockname;
	uv_tcp_getpeername(&clientData->tcpHandle, (struct sockaddr *) &sockname, &namelen);

	//初始化一些客户端连接信息
	strcpy_s(clientData->ip, (char*)inet_ntoa(sockname.sin_addr));
	clientData->port = ntohs(sockname.sin_port);
	clientData->session = g_session;	//记录会话编号
	g_session++;

	///将新的结构放入链表当中 TODO使用链表来处理，查询效率比较低，需要做优化，换一种比较高效的数据结构
	//INSERT_TO_LIST(g_clientDataList, clientData, m_prev, m_next);
	HASH_ADD_INT(g_clientDataList, session, clientData);

	//通知lua
	if (g_luaHandel != NULL)
	{
		//LOGF("[%s:%d]\n", clientData->ip, clientData->port);
		lua_getglobal(g_luaHandel, "lua_onconn");
		lua_pushinteger(g_luaHandel, clientData->session);
		if (lua_pcall(g_luaHandel, 1, 0, 0) != 0)
		{
			//LOGF("Error:runing luafunction [lua_onconn], %s\r\n", lua_tostring(g_luaHandel, -1));
			lua_error(g_luaHandel, lua_tostring(g_luaHandel, -1));
		}
	}

	r = uv_read_start((uv_stream_t*)&clientData->tcpHandle, alloc_cb, read_cb);
	if (r != 0)
	{
		//断开连接
		closeClientConn(clientData);
	}
}

static void alloc_cb(uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf)
{
	static char slab[dMAX_SOCKET_RECV_BUFF];
	buf->base = slab;
	buf->len = sizeof(slab);
}

static void read_cb(uv_stream_t* stream, ssize_t nread, const uv_buf_t* buf) 
{
	CLIENTDATA *clientData = NULL;
	clientData = container_of(stream, CLIENTDATA, tcpHandle);
	if (clientData == NULL)
	{
		//TODO找不到该用户的实现，直接关掉
		return;
	}

	if (nread >= 0)
	{
		//直接扔给lua来处理
		if (g_luaHandel != NULL)
		{
			char bufStr[dMAX_SOCKET_RECV_BUFF];//new char[nread + 1];
			//fprintf(stderr,"#############[%d]#############\n", nread);
			memcpy(&bufStr, buf->base, nread);
			lua_getglobal(g_luaHandel, "lua_onrecv");
			lua_pushlstring(g_luaHandel, bufStr, nread);
			lua_pushinteger(g_luaHandel, clientData->session);
			lua_pushfstring(g_luaHandel, clientData->ip);
			lua_pushinteger(g_luaHandel, clientData->port);
			if (lua_pcall(g_luaHandel, 4, 0, 0) != 0)
			{
				//LOGF("Error:runing luafunction [lua_onrecv], %s\r\n", lua_tostring(g_luaHandel, -1));
				lua_error(g_luaHandel, lua_tostring(g_luaHandel, -1));
			}
			*bufStr = '\0';
		}
		return;
	}

	//可能是客户端主动断开了连接，得通知lua
	if (g_luaHandel != NULL)
	{
		lua_getglobal(g_luaHandel, "lua_oncloseconn");
		lua_pushinteger(g_luaHandel, clientData->session);
		if (lua_pcall(g_luaHandel, 1, 0, 0) != 0)
		{
			//LOGF("Error:runing luafunction [lua_oncloseconn], %s\r\n", lua_tostring(g_luaHandel, -1));
			lua_error(g_luaHandel, lua_tostring(g_luaHandel, -1));
		}
	}
}

static void closeClientConn(CLIENTDATA *clientData)
{
	//LOGF("closeClientConn#############################!!!!!!!!!!!!!!!!!!!!!!\n");
	uv_shutdown(&clientData->shutdown_req, (uv_stream_t*) &clientData->tcpHandle, shutdown_cb);
}

static void shutdown_cb(uv_shutdown_t* req, int status) 
{
	CLIENTDATA* clientData = container_of(req, CLIENTDATA, shutdown_req);
	//LOGF("shutdown_cb#############################!!!!!!!!!!!!!!!!!!!!!!\n");
	if (clientData != NULL)
	{		
		//LOGF("shutdown_cb#############################!!!!!!!!!!!!!!!!!!!!!!111111111\n");
		uv_close((uv_handle_t*)&clientData->tcpHandle, close_cb);
	}	
}

static void close_cb(uv_handle_t* handle) 
{
	CLIENTDATA* clientData = container_of(handle, CLIENTDATA, tcpHandle);	
	if (clientData)
	{
		int session = clientData->session;
		//REMOVE_FROM_LIST(g_clientDataList, clientData, m_prev, m_next);
		HASH_DEL(g_clientDataList, clientData);
		free(clientData);
		clientData = NULL;

		//完全断开连接了，需要调用lua的一个函数
		if (g_luaHandel != NULL)
		{
			lua_getglobal(g_luaHandel, "lua_onFinalClosed");
			lua_pushinteger(g_luaHandel, session);
			if (lua_pcall(g_luaHandel, 1, 0, 0) != 0)
			{
				lua_error(g_luaHandel, lua_tostring(g_luaHandel, -1));
			}
		}
	}

	//LOGF("close_cb#############################!!!!!!!!!!!!!!!!!!!!!!\n");
}

//给lua调用的
static int cppCloseClientConn(lua_State *L)
{
	if (g_luaHandel != NULL)
	{
		//LOGF("cppCloseClientConn#############################!!!!!!!!!!!!!!!!!!!!!!\n");
		if (1 != lua_gettop(L))	return 0;		
		if (!lua_isnumber(L, 1))
		{
			lua_error(g_luaHandel, "lua param is not a number!!!!");
			return 0;
		}
		int session = lua_tointeger(L, 1);
		P_CLIENTDATA client = getClientDataBySession(session);
		if (client != NULL)
		{
			closeClientConn(client);
			return 1;
		}
	}
	return 0;
}

//#################################断开服务器连接########################################
//给lua调用主动断开服务器
static int cppCloseServerConn(lua_State *L)
{
	if (g_luaHandel != NULL)
	{
		if (1 != lua_gettop(L))	return 0;		
		if (!lua_isnumber(L, 1))
		{
			lua_error(g_luaHandel, "lua param is not a number!!!!");
			return 0;
		}
		int sno = lua_tointeger(L, 1);
		P_SERVERDATA server = getServerDataBySno(sno);
		if (server != NULL)
		{
			closeServerConn(server);
			return 1;
		}
	}
	return 0;
}

static void closeServerConn(SERVERDATA *serverData)
{
	uv_shutdown(&serverData->shutdown_req, (uv_stream_t*) &serverData->tcpHandle, shutdownSC_cb);
}

static void shutdownSC_cb(uv_shutdown_t* req, int status) 
{
	SERVERDATA* serverData = container_of(req, SERVERDATA, shutdown_req);
	if (serverData != NULL)
	{		
		uv_close((uv_handle_t*)&serverData->tcpHandle, closeSC_cb);
	}	
}

static void closeSC_cb(uv_handle_t* handle) 
{
	SERVERDATA* serverData = container_of(handle, SERVERDATA, tcpHandle);	
	if (serverData)
	{
		int sno = serverData->sno;
		HASH_DEL(g_serverDataList, serverData);
		free(serverData);
		serverData = NULL;

		//完全断开连接了，需要调用lua的一个函数
		if (g_luaHandel != NULL)
		{
			lua_getglobal(g_luaHandel, "lua_onServerFinalClosed");
			lua_pushinteger(g_luaHandel, sno);
			if (lua_pcall(g_luaHandel, 1, 0, 0) != 0)
			{
				lua_error(g_luaHandel, lua_tostring(g_luaHandel, -1));
			}
		}
	}
}
//#################################断开服务器连接########################################

static P_CLIENTDATA getClientDataBySession(int session)
{
	/*
	P_CLIENTDATA client, next_client;
	LIST_WHILE(g_clientDataList, client, next_client, m_next);
	if (client->session == session)
	{
		return client;
	}
	LIST_WHILEEND(g_clientDataList, client, next_client);
	*/
	P_CLIENTDATA client = NULL;
	HASH_FIND_INT(g_clientDataList, &session, client);
	return client;
}

static P_SERVERDATA getServerDataBySno(int sno)
{
	/*
	P_SERVERDATA server, next_server;
	LIST_WHILE(g_serverDataList, server, next_server, m_next);
	if (server->sno == sno)
	{
		return server;
	}
	LIST_WHILEEND(g_serverDataList, server, next_server);
	*/
	P_SERVERDATA server = NULL;
	HASH_FIND_INT(g_serverDataList, &sno, server);
	return server;
}

static int onSend(lua_State *L)
{	
	if (4 != lua_gettop(L))	return 0;	
	if (lua_isnumber(L, 1) != 1) { log("发送失败"); return 0; }
	if (lua_isstring(L, 2) != 1) { log("发送失败"); return 0; }
	if (lua_isnumber(L, 3) != 1) { log("发送失败"); return 0; }
	if (lua_isnumber(L, 4) != 1) { log("发送失败"); return 0; }

	int len = lua_tointeger(L, 1);
	size_t len_t = len;
	//fprintf(stderr,"#############[send=%d]#############\n", len);
	const char *data = lua_tolstring(L, 2, &len_t);	
	char bufStr[dMAX_SOCKET_SEND_BUFF];	
	memcpy(&bufStr, data, len);
	int session = lua_tointeger(g_luaHandel, 3);
	int op = lua_tointeger(g_luaHandel, 4);
	if (op == 1)	//client
	{
		P_CLIENTDATA clientData = getClientDataBySession(session);
		if (clientData != NULL)
		{
			//clientData->write_buf = uv_buf_init(bufStr, len);
			write_req* write_buf = (write_req*) malloc(sizeof(*write_buf));
			if (!write_buf) { log("memory is not emough!!"); return 0; }
			write_buf->buf = uv_buf_init(bufStr, len);
			
			if (uv_write(&write_buf->req, (uv_stream_t*)&clientData->tcpHandle, &write_buf->buf, 1, after_write) != 0) 
			{
				// TODO 这里不能再知LUA来处理了，因为如果两个用户都断开了连接，然后LUA需要通知对方，那么就会跑来这里，而此时会发生写错误，又
				//	通知LUA这个人下线了，如此一来，死循环了，下面的代码改改，比如执行另外的一个函数？
				//发生了写错误，通知lua断开连接，因为可能游戏内容要保存，所以此处不能直接断开连接
				/*
				lua_getglobal(L, "lua_oncloseconn");
				lua_pushinteger(L, clientData->session);
				if (lua_pcall(L, 1, 0, 0) != 0)
				{
					//LOGF("Error:runing luafunction [lua_oncloseconn], %s\r\n", lua_tostring(L, -1));
					lua_error(g_luaHandel, lua_tostring(g_luaHandel, -1));
				}
				*/
			}
		}
		else
		{
			log("找不到可发送数据的用户！");
		}
	}
	else if (op == 0)	//server
	{
		P_SERVERDATA serverData = getServerDataBySno(session);
		if (serverData != NULL)
		{
			write_req* write_buf = (write_req*) malloc(sizeof(*write_buf));
			if (!write_buf) { log("memory is not emough!!"); return 0; }
			write_buf->buf = uv_buf_init(bufStr, len);

			if (uv_write(&write_buf->req, (uv_stream_t*)&serverData->tcpHandle, &write_buf->buf, 1, after_write) != 0) 
			{
				//TODO发送给服务器的信息出错了，是不是服务器崩了啊？？？？？
			}
		}
		else
		{
			log("找不到可发送数据的服务器！");
		}
	}
	return 1;
}

static void after_write(uv_write_t* req, int status)
{
	//暂时没有可以处理的事情	
	write_req *write_buf;
	write_buf = container_of(req, write_req, req);
	if (write_buf != NULL)
	{
		free(write_buf);
		write_buf = NULL;
	}
}

//数据库处理
typedef struct
{
	char *key;
	char *value;
	int colno;
	int valueType;
} dbrowinfo_t;	//列信息

typedef struct
{
	char *address;
	char *username;
	char *pass;
	char *dbname;
	int port;
	char *sql;
	int token;	

	int dbrowinfo_count;
	dbrowinfo_t* dbrowinfo;

	uv_work_t work_req;
} dbinfo_t;

static int onExcuteSql(lua_State *L)
{
	int paramCount = lua_gettop(L);	//获取参数个数
	if (paramCount != 7) return 0;

	if (lua_isstring(L, 1) != 1) { log("参数不对，执行失败"); return 0; }
	if (lua_isstring(L, 2) != 1) { log("参数不对，执行失败"); return 0; }
	if (lua_isstring(L, 3) != 1) { log("参数不对，执行失败"); return 0; }
	if (lua_isstring(L, 4) != 1) { log("参数不对，执行失败"); return 0; }
	if (lua_isnumber(L, 5) != 1) { log("参数不对，执行失败"); return 0; }
	if (lua_isstring(L, 6) != 1) { log("参数不对，执行失败"); return 0; }
	if (lua_isnumber(L, 7) != 1) { log("参数不对，执行失败"); return 0; }

	const char *address = lua_tostring(L, 1);	//数据库ip
	const char *username = lua_tostring(L, 2);	//用户名
	const char *pass = lua_tostring(L, 3);	//密码
	const char *dbname = lua_tostring(L, 4);	//数据库名
	int port = lua_tointeger(L, 5);	//端口号
	const char *sql = lua_tostring(L, 6);	//要执行的语句	
	int token = lua_tointeger(L, 7);	//回调函数编号

	dbinfo_t* dbinfo;
	dbinfo = (dbinfo_t*) malloc(sizeof *dbinfo);
	dbinfo->address = new char[strlen(address) + 1];
	sprintf(dbinfo->address, "%s", address);
	dbinfo->username = new char[strlen(username) + 1];
	sprintf(dbinfo->username, "%s", username);
	dbinfo->pass = new char[strlen(pass) + 1];
	sprintf(dbinfo->pass, "%s", pass);
	dbinfo->dbname = new char[strlen(dbname) + 1];
	sprintf(dbinfo->dbname, "%s", dbname);
	dbinfo->port = port;
	dbinfo->sql = new char[strlen(sql) + 1];
	sprintf(dbinfo->sql, "%s", sql);
	dbinfo->token = token;
	dbinfo->dbrowinfo = NULL;
	dbinfo->dbrowinfo_count = -1;

	//LOGF("[%s]\r\n", dbinfo->sql);	

	//将其扔到工作线程池里搞之
	int r;
	r = uv_queue_work(g_loop, &dbinfo->work_req, work_cb, after_work_cb);
	if (r != 0)
	{
		//TODO 失败了，没法pop进去，想想办法解决呗
		return 0;
	}	
	return 1;
}

static void work_cb(uv_work_t* req)
{	
	dbinfo_t* dbinfo;
	dbinfo = container_of(req, dbinfo_t, work_req);

	if (dbinfo != NULL)
	{
		MYSQL *conn = NULL;
		conn = mysql_init(conn);
		if (conn == NULL)
		{
			//log("数据库连接初始化失败!!!!!!");
			char logbuf[dMAX_LOG_BUFF];
			if (strlen(dbinfo->sql) >= dMAX_LOG_BUFF)
			{
				sprintf(logbuf, "Error making query: %s!!!\r\nsql to long can not print\r\n", mysql_error(conn));
			}
			else
			{
				sprintf(logbuf, "Error making query: %s!!!\r\n%s\r\n", mysql_error(conn), U2G(dbinfo->sql));
			}			
			log(logbuf);
			return;
		}
		//fprintf(stderr, "执行中11\n");
		if (!mysql_real_connect(conn, dbinfo->address, dbinfo->username, dbinfo->pass, dbinfo->dbname, dbinfo->port, NULL, CLIENT_MULTI_STATEMENTS))
		{
			//连接失败了						
			char logbuf[dMAX_LOG_BUFF];
			if (strlen(dbinfo->sql) >= dMAX_LOG_BUFF)
			{
				sprintf(logbuf, "Error making query: %s!!!\r\nsql to long can not print\r\n", mysql_error(conn));
			}
			else
			{
				sprintf(logbuf, "Error making query: %s!!!\r\n%s\r\n", mysql_error(conn), U2G(dbinfo->sql));
			}			
			log(logbuf);
			mysql_close(conn);
			conn = NULL;
			return;
		}

		if (mysql_query(conn, "SET NAMES UTF8"))
		{
			char logbuf[dMAX_LOG_BUFF];
			//sprintf(logbuf, "数据库设置编码失败！%s\r\n", mysql_error(conn));
			if (strlen(dbinfo->sql) >= dMAX_LOG_BUFF)
			{
				sprintf(logbuf, "Error making query: %s!!!\r\nsql to long can not print\r\n", mysql_error(conn));
			}
			else
			{
				sprintf(logbuf, "Error making query: %s!!!\r\n%s\r\n", mysql_error(conn), U2G(dbinfo->sql));
			}			
			log(logbuf);
			mysql_close(conn);
			conn = NULL;
			return;
		}

		//fprintf(stderr, "执行中22\n");	
		//LOGF("[%s] token=%d\r\n", dbinfo->sql, dbinfo->token);
		//执行sql语句
		if (mysql_real_query(conn, dbinfo->sql, strlen(dbinfo->sql)))
		{
			//fprintf(stderr, "Error making query: %s!!!\r\n[%s]\r\n", mysql_error(conn), dbinfo->sql);
			char logbuf[dMAX_LOG_BUFF];
			if (strlen(dbinfo->sql) >= dMAX_LOG_BUFF)
			{
				sprintf(logbuf, "Error making query: %s!!!\r\nsql to long can not print\r\n", mysql_error(conn));
			}
			else
			{
				sprintf(logbuf, "Error making query: %s!!!\r\n%s\r\n", mysql_error(conn), U2G(dbinfo->sql));			
			}			
			log(logbuf);
			if (conn != NULL)
			{
				mysql_close(conn);
				conn = NULL;
			}
			return;
		}

		MYSQL_RES *res = mysql_store_result(conn);
		if (res == NULL)	//可能是更新操作，也可能是执行失败了
		{
			int eff_row = -1;
			if (strcmp(mysql_error(conn), "") == 0 && mysql_errno(conn) == 0)	//执行成功了
			{
				eff_row = (int) mysql_insert_id(conn);
			}
			dbinfo->dbrowinfo = NULL;
			dbinfo->dbrowinfo_count = eff_row;
		}
		else
		{
			MYSQL_ROW row;
			MYSQL_FIELD *fieldName = mysql_fetch_fields(res);	//取出列名
			dbinfo->dbrowinfo_count = mysql_num_fields(res) * mysql_num_rows(res);	//获取一共多少数据
			dbinfo->dbrowinfo = new dbrowinfo_t[dbinfo->dbrowinfo_count + 1];
			int count = 0;
			int cloNo = 1;	//编号		
			while(row = mysql_fetch_row(res))
			{
				DWORD t;
				for (t = 0; t < mysql_num_fields(res); t++)
				{
					dbrowinfo_t rowinfo;
					//rowinfo.key = fieldName[t].name;
					rowinfo.key = new char[strlen(fieldName[t].name) + 1];
					sprintf(rowinfo.key, "%s", fieldName[t].name);
					if (IS_NUM(fieldName[t].type))
					{
						rowinfo.valueType = 1;	//number
					}
					else
					{						
						rowinfo.valueType = 0;	//string						
					}
					//rowinfo.value = row[t];					
					if (row[t] == NULL)
					{
						rowinfo.value = new char[1];
						if (rowinfo.valueType == 1) sprintf(rowinfo.value, "%s", "0");
						else sprintf(rowinfo.value, "%s", "");
					}
					else
					{
						rowinfo.value = new char[strlen(row[t]) + 1];
						sprintf(rowinfo.value, "%s", row[t]);
					}					
					rowinfo.colno = cloNo;
					dbinfo->dbrowinfo[count] = rowinfo;
					count++;
				}
				cloNo++;
			}
		}

		if (res != NULL)
		{
			mysql_free_result(res);
			res = NULL;
		}

		if (conn != NULL)
		{
			mysql_close(conn);
			conn = NULL;
		}
	}
}

static void after_work_cb(uv_work_t* req, int status)
{
	if (status != 0) return;
	//fprintf(stderr, "执行完成\n");		
	dbinfo_t* dbinfo;
	dbinfo = container_of(req, dbinfo_t, work_req);

	if (dbinfo != NULL)
	{
		if (g_luaHandel != NULL)
		{
			lua_getglobal(g_luaHandel, "lua_onsql");
			lua_newtable(g_luaHandel);

			if (dbinfo->dbrowinfo == NULL)	//执行更新或失败了
			{
				lua_pushstring(g_luaHandel, "ret");
				if (dbinfo->dbrowinfo_count == -1)
				{
					lua_pushinteger(g_luaHandel, -1);
				}
				else
				{
					lua_pushinteger(g_luaHandel, 1);
				}
				lua_settable(g_luaHandel, -3);
				lua_pushstring(g_luaHandel, "eff_row");	//代表影响的行数
				lua_pushinteger(g_luaHandel, dbinfo->dbrowinfo_count);
				lua_settable(g_luaHandel, -3);
			}
			else
			{
				int lastcol = 0;	//控制创建表
				//fprintf(stderr, "totalcount=%d\n", dbinfo->dbrowinfo_count);
				for (int i=0; i < dbinfo->dbrowinfo_count; i++)
				{
					dbrowinfo_t rowinfo = dbinfo->dbrowinfo[i];
					dbrowinfo_t next_rowinfo;
					if (i < dbinfo->dbrowinfo_count - 1)
					{
						next_rowinfo = dbinfo->dbrowinfo[i + 1];
					}
					//fprintf(stderr, "key=%s  value=%s  colno=%d\n", rowinfo.key, rowinfo.value, rowinfo.colno);
					if (lastcol != rowinfo.colno)
					{
						lua_pushinteger(g_luaHandel, rowinfo.colno);
						lua_newtable(g_luaHandel);
						lastcol = rowinfo.colno;
					}
					lua_pushstring(g_luaHandel, rowinfo.key);
					if (rowinfo.valueType == 1)
					{
						lua_pushnumber(g_luaHandel, myatof(rowinfo.value));
					}
					else
					{
						lua_pushstring(g_luaHandel, rowinfo.value);
					}					
					lua_settable(g_luaHandel, -3);
					if ((i < dbinfo->dbrowinfo_count - 1 && next_rowinfo.colno != lastcol) || i == dbinfo->dbrowinfo_count - 1)
					{
						lua_settable(g_luaHandel, -3);
					}
				}
			}
			lua_pushinteger(g_luaHandel, dbinfo->token);
			if (lua_pcall(g_luaHandel, 2, 0, 0) != 0)
			{
				//LOGF("Error:runing luafunction [lua_onsql], %s\r\n", lua_tostring(g_luaHandel, -1));
				lua_error(g_luaHandel, lua_tostring(g_luaHandel, -1));
			}
		}		
	}
	else
	{
		//TODO 回调执行失败了
	}	
	if (dbinfo->dbrowinfo != NULL)
	{
		for (int i=0; i < dbinfo->dbrowinfo_count; i++)
		{
			dbrowinfo_t rowinfo = dbinfo->dbrowinfo[i];
			delete[] rowinfo.key;
			delete[] rowinfo.value;
		}
		delete[] dbinfo->dbrowinfo;
	}
	if (dbinfo->address != NULL) { delete[] dbinfo->address;}
	if (dbinfo->dbname != NULL) { delete[] dbinfo->dbname;}
	if (dbinfo->username != NULL) { delete[] dbinfo->username;}
	if (dbinfo->pass != NULL) { delete[] dbinfo->pass;}	
	if (dbinfo->sql != NULL) { delete[] dbinfo->sql;}
	free(dbinfo);
	dbinfo = NULL;
}

//UTF-8到GB2312的转换
char* U2G(const char* utf8)
{
	int len = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, NULL, 0);
	wchar_t* wstr = new wchar_t[len+1];
	memset(wstr, 0, len+1);
	MultiByteToWideChar(CP_UTF8, 0, utf8, -1, wstr, len);
	len = WideCharToMultiByte(CP_ACP, 0, wstr, -1, NULL, 0, NULL, NULL);
	char* str = new char[len+1];
	memset(str, 0, len+1);
	WideCharToMultiByte(CP_ACP, 0, wstr, -1, str, len, NULL, NULL);
	if(wstr) delete[] wstr;
	return str;
}

//GB2312到UTF-8的转换
char* G2U(const char* gb2312)
{
	int len = MultiByteToWideChar(CP_ACP, 0, gb2312, -1, NULL, 0);
	wchar_t* wstr = new wchar_t[len+1];
	memset(wstr, 0, len+1);
	MultiByteToWideChar(CP_ACP, 0, gb2312, -1, wstr, len);
	len = WideCharToMultiByte(CP_UTF8, 0, wstr, -1, NULL, 0, NULL, NULL);
	char* str = new char[len+1];
	memset(str, 0, len+1);
	WideCharToMultiByte(CP_UTF8, 0, wstr, -1, str, len, NULL, NULL);
	if(wstr) delete[] wstr;
	return str;
}

static int _U(lua_State *L)
{
	int n = lua_gettop(L);
	if (n != 1)
	{
		char buf[50];
		sprintf(buf, "ERROR:script_lua.cpp/_U param count=%d\r\n", n);
		log(buf);
		return 0;
	}
	if (lua_isstring(L, 1) != 1) { log("参数不对！"); return 0; }
	const char *value = lua_tostring(L, 1);
	char *gbstr = U2G(value);	
	lua_pushfstring(L, gbstr);
	return 1;
}

char* bin2hex(unsigned char* bin, int binLength)
{
    static const char* hextable = "0123456789abcdef";
    
    int hexLength = binLength * 2 + 1;
    char* hex = new char[hexLength];
    memset(hex, 0, sizeof(char) * hexLength);
    
    int ci = 0;
    for (int i = 0; i < 16; ++i)
    {
        unsigned char c = bin[i];
        hex[ci++] = hextable[(c >> 4) & 0x0f];
        hex[ci++] = hextable[c & 0x0f];
    }
    
    return hex;
}

static int md5(lua_State *L)
{
	int n = lua_gettop(L);
	if (n != 1) return 0;
	if (lua_isstring(L, 1) != 1) { log("参数不对！"); return 0; }
	const char* value = lua_tostring(L, 1);	
	char *bmd5 = new char[strlen(value) + 1];
	sprintf(bmd5, "%s", value);
	MD5_CTX ctx;
    MD5_Init(&ctx);
    MD5_Update(&ctx, bmd5, strlen(bmd5));
	unsigned char output[16];
    MD5_Final(output, &ctx);	
	char *hex = bin2hex(output, 16);
	char retValue[33];
	sprintf(retValue, "%s", hex);
	lua_pushfstring(L, retValue);
	delete[] bmd5;
	delete[] hex;
	return 1;
}

static int _getServerTime(lua_State *L)
{
	uint64_t timevalue = getServerTime();
	lua_pushnumber(g_luaHandel, timevalue);
	return 1;
}