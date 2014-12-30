/*
	Author: limenghong
	Date: 2014/7/18

	定义lua脚本相关内容
*/

#ifndef __LUASCRIPT_H__
#define __LUASCRIPT_H__

#include "lua.hpp"
#pragma comment(lib,"lua51.lib")

lua_State * initLuaScript();
int loadLuaScript(lua_State *L);
int lua_print(lua_State *L);
void lua_error(lua_State *L, const char * errorMessage);

#endif