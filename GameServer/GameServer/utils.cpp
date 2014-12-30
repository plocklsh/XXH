#include "GameServerConfig.h"
#include "utils.h"
#include <stdio.h>
#include <time.h>
#include <sys/timeb.h>
#include <stdarg.h>
#include <string.h>
#include "uv.h"

//函数名：myatof
//功能：把字符串转化成double浮点型
//名字来源：my array to floating point numbers  
//函数说明：接收一个字符串判断第一个字符的符号，没有符号默认为正值，然后对剩余字符串进行转换，//遇到\0结束，最后返回一个double
double myatof(const char* sptr)
{
    double temp=10;
    bool ispnum=true;
    double ans=0;
    if(*sptr=='-')//判断是否是负数
    {
        ispnum=false;
        sptr++;
    }
    else if(*sptr=='+')//判断是否为正数
    {
        sptr++;
    }

    while(*sptr!='\0')//寻找小数点之前的数
    {
        if(*sptr=='.'){ sptr++;break;}
        ans=ans*10+(*sptr-'0');
        sptr++;
    }
    while(*sptr!='\0')//寻找小数点之后的数
    {
        ans=ans+(*sptr-'0')/temp;
        temp*=10;
        sptr++;
    }
    if(ispnum) return ans;
    else return ans*(-1);
}

//函数名：myatoi
//功能：把字符串转化成int整型
//名字来源：my array to integer  
//函数说明：接收一个字符串判断第一个字符的符号，没有符号默认为正值，然后对剩余字符串进行转换，//遇到\0结束，最后返回一个int
int myatoi(const char* sptr)
{

    bool ispnum=true;
    int ans=0;
    if(*sptr=='-')//判断是否是负数
    {
        ispnum=false;
        sptr++;
    }
    else if(*sptr=='+')//判断是否为正数
    {
        sptr++;
    }

    while(*sptr!='\0')//类型转化
    {
        ans=ans*10+(*sptr-'0');
        sptr++;
    }

    if(ispnum) return ans;
    else return ans*(-1);
}

void saveLog(const char *fileName, const char *logValue)
{	
	FILE *fp;
	fopen_s(&fp, fileName, "a");
	if (!fp) return;	
	fprintf_s(fp, "%s", logValue);
	fclose(fp);
}

uint64_t getServerTime()
{
	struct __timeb64 timebuffer;
	_ftime64(&timebuffer);
	uint64_t timevalue = timebuffer.time * 1000 + timebuffer.millitm;
	return timevalue;
}

void getTimeStr(char *timestr)
{	
	//const time_t now_t = time(NULL);
	struct __timeb64 timebuffer;
	_ftime64(&timebuffer);
	struct tm* current_time = localtime(&timebuffer.time);
	if (!current_time) return;
	sprintf(timestr, "%d-%02d-%02d %02d:%02d:%02d.%03hu", 
		current_time->tm_year + 1900,
		current_time->tm_mon + 1,
		current_time->tm_mday,
		current_time->tm_hour,
		current_time->tm_min,
		current_time->tm_sec,
		timebuffer.millitm);
}

void log(const char *buf)
{
	//const time_t now_t = time(NULL);
	struct __timeb64 timebuffer;
	_ftime64(&timebuffer);
	struct tm* current_time = localtime(&timebuffer.time);
	if (!current_time) return;
	char timestr[32];
	sprintf(timestr, "%d-%02d-%02d %02d:%02d:%02d.%03hu", 
		current_time->tm_year + 1900,
		current_time->tm_mon + 1,
		current_time->tm_mday,
		current_time->tm_hour,
		current_time->tm_min,
		current_time->tm_sec,
		timebuffer.millitm);

	if (strlen(buf) > dMAX_LOG_BUFF)
	{
		LOG("log size > 100K");
		return;
	}
	char t_buf[dMAX_LOG_BUFF];	
	sprintf(t_buf, "[%s] %s\n\r", timestr, buf);
	char fileName[40];
	sprintf(fileName, "logs/%s_%d_%02d_%02d.txt", SEVERNAME, current_time->tm_year + 1900, current_time->tm_mon + 1, current_time->tm_mday);	
	saveLog(fileName, t_buf);
	LOG(t_buf);
}