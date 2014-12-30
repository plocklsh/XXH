/*
	Author: limenghong
	Date: 2014/7/18
*/

#ifndef __GAMESERVER_H__
#define __GAMESERVER_H__

#define dMAX_SOCKET_RECV_BUFF	65536
#define dMAX_SOCKET_SEND_BUFF	65536

typedef struct
{
	uv_write_t req;
	uv_buf_t buf;
} write_req;

//定义连接信息结构
struct clientData_t
{
	char ip[20];
	int port;
	int session;

	uv_tcp_t tcpHandle;
	uv_shutdown_t shutdown_req;

	//uv_write_t write_req;
	//uv_buf_t write_buf;

	//定义链表连接的指针
	//struct clientData_t *m_prev;
	//struct clientData_t *m_next;
	
	UT_hash_handle hh;
};
typedef clientData_t CLIENTDATA, *P_CLIENTDATA;

//定义服务器信息结构
struct serverData_t
{
	char ip[20];
	int port;
	int sno;	//服务器编号

	uv_tcp_t tcpHandle;
	uv_connect_t connect_reqs;
	uv_shutdown_t shutdown_req;

	//uv_write_t write_req;
	//uv_buf_t write_buf;

	//定义链表连接的指针
	//struct serverData_t *m_prev;
	//struct serverData_t *m_next;

	UT_hash_handle hh;
};
typedef serverData_t SERVERDATA, *P_SERVERDATA;

static void enterFrame(uv_timer_t* handle);
static int reloadScript(lua_State *L);
#if defined(_WIN32)
	BOOL ctrlHandler(DWORD fdwCtrlType);
#else
	//TODO添加unix的支持
#endif
static int closeServerFinal(lua_State *L);
static int closeServer(lua_State *L);
static void doCloseServer();
static int initListener(lua_State *L);
static int connectTo(lua_State *L);
static void connect_cb(uv_connect_t* req, int status);
static void read_server_cb(uv_stream_t* stream, ssize_t nread, const uv_buf_t* buf);
static void newClientConnection(uv_stream_t* stream, int status);
static void alloc_cb(uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf);
static void read_cb(uv_stream_t* stream, ssize_t nread, const uv_buf_t* buf);
static void closeClientConn(CLIENTDATA *clientData);
static void shutdown_cb(uv_shutdown_t* req, int status);
static void close_cb(uv_handle_t* handle);
static int cppCloseClientConn(lua_State *L);
static P_CLIENTDATA getClientDataBySession(int session);
static int onSend(lua_State *L);
static void after_write(uv_write_t* req, int status);
static int onExcuteSql(lua_State *L);
static void work_cb(uv_work_t* req);
static void after_work_cb(uv_work_t* req, int status);
char* U2G(const char* utf8);
char* G2U(const char* gb2312);
static int _U(lua_State *L);
static int md5(lua_State *L);
static int _getServerTime(lua_State *L);
static int cppCloseServerConn(lua_State *L);
static void closeServerConn(SERVERDATA *serverData);
static void shutdownSC_cb(uv_shutdown_t* req, int status);
static void closeSC_cb(uv_handle_t* handle);
static P_SERVERDATA getServerDataBySno(int sno);
#endif