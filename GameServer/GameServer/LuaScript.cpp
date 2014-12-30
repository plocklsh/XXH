/*
	Author: limenghong
	Date: 2014/7/18

	定义lua脚本相关内容
*/

#include "GameServerConfig.h"
#include "LuaScript.h"
#include "utils.h"
#include <string>
#include <time.h>
using namespace std;

lua_State * initLuaScript()
{
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	return L;
}

int loadLuaScript(lua_State *L)
{
	if (L != NULL)
	{
		char configFileName[40];
		sprintf(configFileName, "%s.exe.cfg", SEVERNAME);
		int erro = luaL_loadfile(L, configFileName);
		if (erro != 0)
		{
			//fprintf(stderr, "%s\n", lua_tostring(L, -1));
			return 1;
		}		
		erro = lua_pcall(L, 0, 0, 0);
		if (erro == 0)
		{
			return 0;
		}
		else 
		{
			LOGF("脚本加载失败%s\n", lua_tostring(L, -1));
		}
	}
	lua_close(L);
	return 1;
}

int lua_print(lua_State *L)
{
	int nargs = lua_gettop(L);
	std::string t ("");	
	for (int i=1; i<= nargs; i++)
	{
		if (lua_istable(L, i))
		{
			t += "table";
		} 
		else if (lua_isnone(L, i))
		{
			t += "none";
		}
		else if (lua_isnil(L, i))
		{
			t += "nil"; 
		}
		else if (lua_isboolean(L, i))
        {
            if (lua_toboolean(L, i) != 0)
			{
                t += "true";
			}
            else
			{
                t += "false";
			}
        }
		else if (lua_isfunction(L, i))
		{
            t += "function";
		}
        else if (lua_islightuserdata(L, i))
		{
            t += "lightuserdata";
		}
        else if (lua_isthread(L, i))
		{
            t += "thread";
		}
		else
		{
			const char * str = lua_tostring(L, i);
			if (str)
			{
				t += lua_tostring(L, i);
			}
			else
			{
				t += lua_typename(L, lua_type(L, i));
			}
		}
		if ( i!= nargs)
		{
            t += "  ";
		}
	}
	//t += "\n";	

	log(t.c_str());
	return 0;
}

void lua_error(lua_State *L, const char * errorMessage)
{
	if (errorMessage == NULL) return;
	lua_getglobal(L, "__G__TRACKBACK__");
	lua_pushstring(L, errorMessage);
	if (lua_pcall(L, 1, 0, 0) != 0)
	{
		char logbuf[dMAX_LOG_BUFF];
		sprintf(logbuf, "Error:runing luafunction [__G__TRACKBACK__], %s\r\n", lua_tostring(L, -1));
		log(logbuf);
	}
}