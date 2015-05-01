#include <errno.h>
#include <limits.h>
#include <time.h>

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

EXPORT int  p6_libc_errno_get(void)   { return errno; }
EXPORT void p6_libc_errno_set(int no) { errno = no; }

EXPORT int                p6_libc_limits_char_bit(void)   { return CHAR_BIT; }
EXPORT int                p6_libc_limits_schar_min(void)  { return SCHAR_MIN; }
EXPORT int                p6_libc_limits_schar_max(void)  { return SCHAR_MAX; }
EXPORT int                p6_libc_limits_uchar_max(void)  { return UCHAR_MAX; }
EXPORT int                p6_libc_limits_char_min(void)   { return CHAR_MIN; }
EXPORT int                p6_libc_limits_char_max(void)   { return CHAR_MAX; }
EXPORT int                p6_libc_limits_mb_len_max(void) { return MB_LEN_MAX; }
EXPORT int                p6_libc_limits_shrt_min(void)   { return SHRT_MIN; }
EXPORT int                p6_libc_limits_shrt_max(void)   { return SHRT_MAX; }
EXPORT int                p6_libc_limits_ushrt_max(void)  { return USHRT_MAX; }
EXPORT int                p6_libc_limits_int_min(void)    { return INT_MIN; }
EXPORT int                p6_libc_limits_int_max(void)    { return INT_MAX; }
EXPORT unsigned           p6_libc_limits_uint_max(void)   { return UINT_MAX; }
EXPORT long               p6_libc_limits_long_min(void)   { return LONG_MIN; }
EXPORT long               p6_libc_limits_long_max(void)   { return LONG_MAX; }
EXPORT unsigned long      p6_libc_limits_ulong_max(void)  { return ULONG_MAX; }
EXPORT long long          p6_libc_limits_llong_min(void)  { return LLONG_MIN; }
EXPORT long long          p6_libc_limits_llong_max(void)  { return LLONG_MAX; }
EXPORT unsigned long long p6_libc_limits_ullong_max(void) { return ULLONG_MAX; }

EXPORT size_t  p6_libc_time_clock_size(void)      { return sizeof (clock_t); }
EXPORT int     p6_libc_time_clock_is_float(void)  { return (clock_t)0.5 == 0.5; }
EXPORT int     p6_libc_time_clock_is_signed(void) { return (clock_t)-1 < 0; }
EXPORT size_t  p6_libc_time_time_size(void)       { return sizeof (time_t); }
EXPORT int     p6_libc_time_time_is_float(void)   { return (time_t)0.5 == 0.5; }
EXPORT int     p6_libc_time_time_is_signed(void)  { return (time_t)-1 < 0; }
EXPORT clock_t p6_libc_time_clocks_per_sec(void)  { return CLOCKS_PER_SEC; }
