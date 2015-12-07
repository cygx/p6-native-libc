# Copyright 2015 cygx <cygx@cpan.org>
# Distributed under the Boost Software License, Version 1.0

my grammar CPPConstExpr {
    # poor man's shunting yard
    sub parse(@toks) {
        my @queue;
        my @stack;

        for @toks {
            when Int { @queue.push($_) }
            when any <* /> { @stack.push($_) }
            when any <+ -> {
                while @stack.tail ~~ any <* /> {
                    return Nil if @queue < 2;
                    my $b = @queue.pop;
                    my $a = @queue.pop;
                    @queue.push($_) given do given @stack.pop {
                        when '*' { $a * $b }
                        when '/' { $a div $b }
                    }
                }

                @stack.push($_);
            }
            default { return Nil }
        }

        while @stack {
            return Nil if @queue < 2;
            my $b = @queue.pop;
            my $a = @queue.pop;
            @queue.push($_) given do given @stack.pop {
                when '+' { $a + $b }
                when '-' { $a - $b }
                when '*' { $a * $b }
                when '/' { $a div $b }
            }
        }

        @queue == 1 ?? @queue[0] !! Nil;
    }

    token TOP {
        <expr>
        { make $<expr>.made }
    }

    token expr {
        \h* <tok=.term> [ \h* <tok=.op> \h* <tok=.term> ]* \h*
        { make parse $<tok>>>.made }
    }

    token op {
        <[+\-*/]>
        { make ~$/ }
    }

    token term {
        [ <val=.int> | <val=.subexpr> ]
        { make $<val>.made }
    }

    token int {
        (<[+-]>?) \h* (\d+) <[uUlL]>*
        { make $0 eq '-' ?? -$1 !! +$1 }
    }

    token subexpr {
        '(' <expr> ')'
        { make $<expr>.made }
    }
}

sub cppeval($expr) { CPPConstExpr.parse($expr).?made // $expr }

BEGIN my %probe;
BEGIN {
    my \HEADER = 'probe.h';
    my \SOURCE = 'probe.c';
    my \BINARY = 'probe.exe';
    LEAVE unlink HEADER, SOURCE, BINARY;

    spurt HEADER, q:to/__END__/;
    #include <errno.h>
    #include <limits.h>
    #include <stdio.h>
    #include <time.h>
    probe_msvc_ver _MSVC_VER
    probe_errno errno
    probe_char_bit CHAR_BIT
    probe_schar_min SCHAR_MIN
    probe_schar_max SCHAR_MAX
    probe_uchar_max UCHAR_MAX
    probe_char_min CHAR_MIN
    probe_char_max CHAR_MAX
    probe_mb_len_max MB_LEN_MAX
    probe_shrt_min SHRT_MIN
    probe_shrt_max SHRT_MAX
    probe_ushrt_max USHRT_MAX
    probe_int_min INT_MIN
    probe_int_max INT_MAX
    probe_uint_max UINT_MAX
    probe_long_min LONG_MIN
    probe_long_max LONG_MAX
    probe_ulong_max ULONG_MAX
    probe_llong_min LLONG_MIN
    probe_llong_max LLONG_MAX
    probe_ullong_max ULLONG_MAX
    probe_iofbf _IOFBF
    probe_iolbf _IOLBF
    probe_ionbf _IONBF
    probe_bufsiz BUFSIZ
    probe_eof EOF
    probe_seek_cur SEEK_CUR
    probe_seek_end SEEK_END
    probe_seek_set SEEK_SET
    probe_clocks_per_sec CLOCKS_PER_SEC
    __END__

    spurt SOURCE, q:to/__END__/;
    #include <stdio.h>
    #include <time.h>
    int main(void) {
        printf("probe_sizeof_clock_t %u\n", (unsigned)sizeof (clock_t));
        printf("probe_isfloat_clock_t %i\n", (clock_t)0.5 == 0.5);
        printf("probe_issigned_clock_t %i\n", (clock_t)-1 < 0);
        printf("probe_sizeof_time_t %u\n", (unsigned)sizeof (time_t));
        printf("probe_isfloat_time_t %i\n", (time_t)0.5 == 0.5);
        printf("probe_issigned_time_t %i\n", (time_t)-1 < 0);
        return 0;
    }
    __END__

    my @static = run(|$*VM.config<cc cppswitch>, HEADER, :out)
        . out.slurp-rest.lines
        . map({ /^probe_(\w+)\h+(.*)/ ?? |(~$0 => cppeval ~$1) !! next });

    run($*VM.config<cc>, $*VM.config<ccout>.trim ~ BINARY, SOURCE);
    my @dynamic = run($*DISTRO.is-win ?? BINARY !! './' ~ BINARY, :out)
        . out.slurp-rest.lines
        . map({ /^probe_(\w+)\h+(.*)/ ?? |(~$0 => +$1) !! next });

    %probe = |@static, |@dynamic;
    %probe<libc> = $_ given do given $*VM.config<os> // $*KERNEL.name {
        when 'mingw32' { 'msvcrt.dll' }

        when 'win32' {
            given %probe<msc_ver> {
                when 800 { 'msvcr10.dll' };
                when 1000..^1300 { 'msvcrt.dll' }
                when Int { "msvcr{ $_ / 10 - 60 }.dll" }
                default { die 'Not sure which CRT DLL to use, sorry...' }
            }
        }

        default { Str }
    }
}

module Native::LibC {
    use nqp;
    use NativeCall;

    my constant KERNEL = $*VM.config<os> // $*KERNEL.name;
    my constant LIBC = %probe<libc>;

    my constant PTRSIZE = nativesizeof(Pointer);
    die "Unsupported pointer size { PTRSIZE }"
        unless PTRSIZE ~~ 4|8;

    constant int    = int32;
    constant uint   = uint32;
    constant llong  = longlong;
    constant ullong = ulonglong;
    constant float  = num32;
    constant double = num64;

    constant intptr_t = do given PTRSIZE {
        when 4 { int32 }
        when 8 { int64 }
    }

    constant uintptr_t = do given PTRSIZE {
        when 4 { uint32 }
        when 8 { uint64 }
    }

    constant size_t    = uintptr_t;
    constant ptrdiff_t = intptr_t;

    constant clock_t = do {
        given %probe<sizeof_clock_t> {
            when 4 {
                if %probe<isfloat_clock_t> { float }
                else { %probe<issigned_clock_t> ?? int32  !! uint32 }
            }
            when 8 {
                if %probe<isfloat_clock_t> { double }
                else { %probe<issigned_clock_t> ?? int64  !! uint64 }
            }
            default { die "Unsupported clock_t size $_" }
        }
    }

    constant time_t = do {
        given %probe<sizeof_time_t> {
            when 4 {
                if %probe<isfloat_time_t> { float }
                else { %probe<issigned_time_t> ?? int32  !! uint32 }
            }
            when 8 {
                if %probe<isfloat_time_t> { double }
                else { %probe<issigned_time_t> ?? int64  !! uint64 }
            }
            default { die "Unsupported time_t size $_" }
        }
    }

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

    our sub NULL { once Ptr.new(0) }

    # <ctype.h>
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

    # <errno.h>
    my constant @ERRNO-BASE =
        :EPERM(1),
        :ENOENT(2),
        :ESRCH(3),
        :EINTR(4),
        :EIO(5),
        :ENXIO(6),
        :E2BIG(7),
        :ENOEXEC(8),
        :EBADF(9),
        :ECHILD(10),
        :EAGAIN(11),
        :ENOMEM(12),
        :EACCES(13),
        :EFAULT(14),
        :ENOTBLK(15),
        :EBUSY(16),
        :EEXIST(17),
        :EXDEV(18),
        :ENODEV(19),
        :ENOTDIR(20),
        :EISDIR(21),
        :EINVAL(22),
        :ENFILE(23),
        :EMFILE(24),
        :ENOTTY(25),
        :ETXTBSY(26),
        :EFBIG(27),
        :ENOSPC(28),
        :ESPIPE(29),
        :EROFS(30),
        :EMLINK(31),
        :EPIPE(32),
        :EDOM(33),
        :ERANGE(34);

    my constant @ERRNO-WIN32 =
        :EDEADLK(36),
        :EDEADLOCK(36),
        :ENAMETOOLONG(38),
        :ENOLCK(39),
        :ENOSYS(40),
        :ENOTEMPTY(41),
        :EILSEQ(42),
        :STRUNCATE(80);

    my constant @ERRNO-LINUX =
        :EDEADLK(35),
        :ENAMETOOLONG(36),
        :ENOLCK(37),
        :ENOSYS(38),
        :ENOTEMPTY(39),
        :ELOOP(40),
        :EWOULDBLOCK(11),
        :ENOMSG(42),
        :EIDRM(43),
        :ECHRNG(44),
        :EL2NSYNC(45),
        :EL3HLT(46),
        :EL3RST(47),
        :ELNRNG(48),
        :EUNATCH(49),
        :ENOCSI(50),
        :EL2HLT(51),
        :EBADE(52),
        :EBADR(53),
        :EXFULL(54),
        :ENOANO(55),
        :EBADRQC(56),
        :EBADSLT(57),
        :EDEADLOCK(35),
        :EBFONT(59),
        :ENOSTR(60),
        :ENODATA(61),
        :ETIME(62),
        :ENOSR(63),
        :ENONET(64),
        :ENOPKG(65),
        :EREMOTE(66),
        :ENOLINK(67),
        :EADV(68),
        :ESRMNT(69),
        :ECOMM(70),
        :EPROTO(71),
        :EMULTIHOP(72),
        :EDOTDOT(73),
        :EBADMSG(74),
        :EOVERFLOW(75),
        :ENOTUNIQ(76),
        :EBADFD(77),
        :EREMCHG(78),
        :ELIBACC(79),
        :ELIBBAD(80),
        :ELIBSCN(81),
        :ELIBMAX(82),
        :ELIBEXEC(83),
        :EILSEQ(84),
        :ERESTART(85),
        :ESTRPIPE(86),
        :EUSERS(87),
        :ENOTSOCK(88),
        :EDESTADDRREQ(89),
        :EMSGSIZE(90),
        :EPROTOTYPE(91),
        :ENOPROTOOPT(92),
        :EPROTONOSUPPORT(93),
        :ESOCKTNOSUPPORT(94),
        :EOPNOTSUPP(95),
        :EPFNOSUPPORT(96),
        :EAFNOSUPPORT(97),
        :EADDRINUSE(98),
        :EADDRNOTAVAIL(99),
        :ENETDOWN(100),
        :ENETUNREACH(101),
        :ENETRESET(102),
        :ECONNABORTED(103),
        :ECONNRESET(104),
        :ENOBUFS(105),
        :EISCONN(106),
        :ENOTCONN(107),
        :ESHUTDOWN(108),
        :ETOOMANYREFS(109),
        :ETIMEDOUT(110),
        :ECONNREFUSED(111),
        :EHOSTDOWN(112),
        :EHOSTUNREACH(113),
        :EALREADY(114),
        :EINPROGRESS(115),
        :ESTALE(116),
        :EUCLEAN(117),
        :ENOTNAM(118),
        :ENAVAIL(119),
        :EISNAM(120),
        :EREMOTEIO(121),
        :EDQUOT(122),
        :ENOMEDIUM(123),
        :EMEDIUMTYPE(124),
        :ECANCELED(125),
        :ENOKEY(126),
        :EKEYEXPIRED(127),
        :EKEYREVOKED(128),
        :EKEYREJECTED(129),
        :EOWNERDEAD(130),
        :ENOTRECOVERABLE(131);

    my Int enum Errno ();
    my Errno @errno;

    BEGIN {
        @errno[.value] = Native::LibC::{.key} :=
            Errno.new(:key(.key), :value(.value)) for flat do given KERNEL {
                when 'win32'|'mingw32' { @ERRNO-BASE, @ERRNO-WIN32 }
                when 'linux' { @ERRNO-BASE, @ERRNO-LINUX }
                default {
                    warn "Unknown kernel '$_'";
                    @ERRNO-BASE;
                }
            }
    }

    our proto errno(|) { * }

    multi sub errno() {
        die 'NYI';
        my \value = 42;
        @errno[value] // value;
    }

    multi sub errno(Int \value) {
        die 'NYI';
        @errno[value] // value;
    }

    # <limits.h>
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

    constant limits = %(
        :CHAR_BIT(CHAR_BIT),
        :SCHAR_MIN(SCHAR_MIN),
        :SCHAR_MAX(SCHAR_MAX),
        :UCHAR_MAX(UCHAR_MAX),
        :CHAR_MIN(CHAR_MIN),
        :CHAR_MAX(CHAR_MAX),
        :MB_LEN_MAX(MB_LEN_MAX),
        :SHRT_MIN(SHRT_MIN),
        :SHRT_MAX(SHRT_MAX),
        :USHRT_MAX(USHRT_MAX),
        :INT_MIN(INT_MIN),
        :INT_MAX(INT_MAX),
        :UINT_MAX(UINT_MAX),
        :LONG_MIN(LONG_MIN),
        :LONG_MAX(LONG_MAX),
        :ULONG_MAX(ULONG_MAX),
        :LLONG_MIN(LLONG_MIN),
        :LLONG_MAX(LLONG_MAX),
        :ULLONG_MAX(ULLONG_MAX)
    );

    # <stdio.h>
    class FILE is repr('CPointer') { ... }

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

    # <time.h>
    constant CLOCKS_PER_SEC = %probe<clocks_per_sec>;

    our sub clock(--> clock_t) is native(LIBC) { * }
    our sub time(Ptr[time_t] --> time_t) is native(LIBC) { * }

    class FILE is Ptr {
        method open(FILE:U: Str \path, Str \mode = 'r') {
            fopen(path, mode)
        }

        method close(FILE:D:) {
            fclose(self) == 0 or fail
        }

        method flush(FILE:D:) {
            fflush(self) == 0 or fail
        }

        method eof(FILE:D:) {
            feof(self) != 0
        }

        method seek(FILE:D: Int \offset, Int \whence) {
            fseek(self, offset, whence) == 0 or fail
        }

        method gets(FILE:D: Ptr() \ptr, int \count) {
            fgets(ptr, count, self) orelse fail
        }
    }
}

sub EXPORT(*@list) {
    Map.new(
        'libc' => Native::LibC,
        @list.map({
            when Native::LibC::{"&$_"}:exists { "&$_" => Native::LibC::{"&$_"} }
            when Native::LibC::{"$_"}:exists { "$_" => Native::LibC::{"$_"} }
            default { die "Unknown identifier '$_'"}
        })
    );
}
