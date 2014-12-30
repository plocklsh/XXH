/*
	Author: limenghong
*/

#ifndef __UTILS_H__
#define __UTILS_H__

/* Log to stderr. */
#define LOG(...)                        \
  do {                                  \
    fprintf(stderr, "%s", __VA_ARGS__); \
    fflush(stderr);                     \
  } while (0)

#define LOGF(...)                       \
  do {                                  \
    fprintf(stderr, __VA_ARGS__);       \
    fflush(stderr);                     \
  } while (0)

#define ASSERT(expr)                                      \
 do {                                                     \
  if (!(expr)) {                                          \
    fprintf(stderr,                                       \
            "Assertion failed in %s on line %d: %s\n",    \
            __FILE__,                                     \
            __LINE__,                                     \
            #expr);                                       \
    abort();                                              \
  }                                                       \
 } while (0)


#define container_of(ptr, type, member) \
  ((type *) ((char *) (ptr) - offsetof(type, member)))



#define dMAX_LOG_BUFF	1024 * 100

double myatof(const char* sptr);
int myatoi(const char* sptr);
void saveLog(const char *fileName, const char *logValue);
void log(const char *buf);
void getTimeStr(char *timestr);
unsigned long long getServerTime();

#endif