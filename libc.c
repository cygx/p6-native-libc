#include <errno.h>

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

EXPORT int p6_libc_errno_get(void)
{
    return errno;
}

EXPORT int p6_libc_errno_set(int no)
{
    errno = no;
}
