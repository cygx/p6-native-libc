# Native::LibC [![Build Status][TRAVISIMG]][TRAVIS]

The C standard library


# Synopsis

```
    use Native::LibC <malloc fopen puts free>;

    my $buf = malloc(1024);
    my $file = fopen('LICENSE', 'r');

    loop { puts(chomp $file.gets($buf, 1024) // last) }

    $file.close;
    free($buf);
```


# Description

Provides access to the C standard library.

This is work in progress and not a finished product. Feel free to
[open a ticket][NEWTICKET] if you need a particular feature that's still
missing.


# LibC API

Overview over the `libc::` namespace, a lexical alias for `Native::LibC::`.

Anything that's missing from this list still needs to be implemented.


## Constants

    constant int    = int32;

    constant uint   = uint32;

    constant llong  = longlong;

    constant ullong = ulonglong;

    constant float  = num32;

    constant double = num64;

    constant intptr_t = do given PTRSIZE { * }

    constant uintptr_t = do given PTRSIZE { * }

    constant size_t    = uintptr_t;

    constant ptrdiff_t = intptr_t;

    constant clock_t = do { * }

    constant time_t = do { * }

    constant _IOFBF   = %probe<iofbf>;

    constant _IOLBF   = %probe<iolbf>;

    constant _IONBF   = %probe<ionbf>;

    constant BUFSIZ   = %probe<bufsiz>;

    constant EOF      = %probe<eof>;

    constant SEEK_CUR = %probe<seek_cur>;

    constant SEEK_END = %probe<seek_end>;

    constant SEEK_SET = %probe<seek_set>;

    constant Ptr = Pointer;

    constant &sizeof = &nativesizeof;

    constant CHAR_BIT   = %probe<char_bit>;

    constant SCHAR_MIN  = %probe<schar_min>;

    constant SCHAR_MAX  = %probe<schar_max>;

    constant UCHAR_MAX  = %probe<uchar_max>;

    constant CHAR_MIN   = %probe<char_min>;

    constant CHAR_MAX   = %probe<char_max>;

    constant MB_LEN_MAX = %probe<mb_len_max>;

    constant SHRT_MIN   = %probe<shrt_min>;

    constant SHRT_MAX   = %probe<shrt_max>;

    constant USHRT_MAX  = %probe<ushrt_max>;

    constant INT_MIN    = %probe<int_min>;

    constant INT_MAX    = %probe<int_max>;

    constant UINT_MAX   = %probe<uint_max>;

    constant LONG_MIN   = %probe<long_min>;

    constant LONG_MAX   = %probe<long_max>;

    constant ULONG_MAX  = %probe<ulong_max>;

    constant LLONG_MIN  = %probe<llong_min>;

    constant LLONG_MAX  = %probe<llong_max>;

    constant ULLONG_MAX = %probe<ullong_max>;

    constant limits = %( * );

    constant CLOCKS_PER_SEC = %probe<clocks_per_sec>;


## Functions

    our sub NULL { once Ptr.new(0) }

    our sub isalnum(int --> int) is native(LIBC) { * }

    our sub isalpha(int --> int) is native(LIBC) { * }

    our sub isblank(int --> int) is native(LIBC) { * }

    our sub iscntrl(int --> int) is native(LIBC) { * }

    our sub isdigit(int --> int) is native(LIBC) { * }

    our sub isgraph(int --> int) is native(LIBC) { * }

    our sub islower(int --> int) is native(LIBC) { * }

    our sub isprint(int --> int) is native(LIBC) { * }

    our sub ispunct(int --> int) is native(LIBC) { * }

    our sub isspace(int --> int) is native(LIBC) { * }

    our sub isupper(int --> int) is native(LIBC) { * }

    our sub isxdigit(int --> int) is native(LIBC) { * }

    our sub tolower(int --> int) is native(LIBC) { * }

    our sub toupper(int --> int) is native(LIBC) { * }

    multi sub errno() { * }

    multi sub errno(Int \value) { * }

    our sub fopen(Str, Str --> FILE) is native(LIBC) { * }

    our sub fclose(FILE --> int) is native(LIBC) { * }

    our sub fflush(FILE --> int) is native(LIBC) { * }

    our sub puts(Str --> int) is native(LIBC) { * }

    our sub fgets(Ptr, int, FILE --> Str) is native(LIBC) { * }

    our sub fread(Ptr, size_t, size_t, FILE --> size_t) is native(LIBC) { * }

    our sub feof(FILE --> int) is native(LIBC) { * }

    our sub fseek(FILE, long, int --> int) is native(LIBC) { * };

    our sub malloc(size_t --> Ptr) is native(LIBC) { * }

    our sub realloc(Ptr, size_t --> Ptr) is native(LIBC) { * }

    our sub calloc(size_t, size_t --> Ptr) is native(LIBC) { * }

    our sub free(Ptr) is native(LIBC) { * }

    our sub memcpy(Ptr, Ptr, size_t --> Ptr) is native(LIBC) { * }

    our sub memmove(Ptr, Ptr, size_t --> Ptr) is native(LIBC) { * }

    our sub memset(Ptr, int, size_t --> Ptr) is native(LIBC) { * }

    our sub memcmp(Ptr, Ptr, size_t --> int) is native(LIBC) { * }

    our sub strlen(Ptr[int8] --> size_t) is native(LIBC) { * }

    our sub system(Str --> int) is native(LIBC) { * }

    our sub exit(int) is native(LIBC) { * }

    our sub abort() is native(LIBC) { * }

    our sub raise(int --> int) is native(LIBC) { * }

    our sub getenv(Str --> Str) is native(LIBC) { * }

    our sub srand(uint) is native(LIBC) { * };

    our sub rand(--> int) is native(LIBC) { * };

    our sub clock(--> clock_t) is native(LIBC) { * }

    our sub time(Ptr[time_t] --> time_t) is native(LIBC) { * }


## Classes

    class FILE is Ptr { * }

        method open(FILE:U: Str \path, Str \mode = 'r') { * }

        method close(FILE:D:) { * }

        method flush(FILE:D:) { * }

        method eof(FILE:D:) { * }

        method seek(FILE:D: Int \offset, Int \whence) { * }

        method gets(FILE:D: Ptr() \ptr, int \count) { * }



# Bugs and Development

Development happens at [GitHub][SOURCE]. If you found a bug or have a feature
request, use the [issue tracker][ISSUES] over there.


# Copyright and License

Copyright (C) 2015 by <cygx@cpan.org>

Distributed under the
[Boost Software License, Version 1.0](http://www.boost.org/LICENSE_1_0.txt)


[TRAVIS]:       https://travis-ci.org/cygx/p6-native-libc
[TRAVISIMG]:    https://travis-ci.org/cygx/p6-native-libc.svg?branch=v2
[SOURCE]:       https://github.com/cygx/p6-native-libc
[ISSUES]:       https://github.com/cygx/p6-native-libc/issues
[NEWTICKET]:    https://github.com/cygx/p6-native-libc/issues/new
[LICENSE]:      http://www.boost.org/LICENSE_1_0.txt
