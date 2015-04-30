module libc {
    use nqp;
    use NativeCall;

    my constant LIBC = $*DISTRO.is-win ?? 'msvcrt.dll' !! '';
    my constant PTRSIZE = nativesizeof(Pointer);
    die "Unsupported pointer size { PTRSIZE }"
        unless PTRSIZE ~~ 4|8;

    constant int  = int32;
    constant uint = uint32;

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

    constant clock_t = long;

    constant Ptr = Pointer;
    constant &sizeof = &nativesizeof;

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

    BEGIN {
        libc::{.key} := .value for flat do given $*KERNEL.name {
            when 'win32' { @ERRNO-BASE, @ERRNO-WIN32 }
            default {
                warn "Unknown kernel '$_'";
                @ERRNO-BASE;
            }
        }
    }

    class FILE is repr('CPointer') { ... }

    our sub fopen(Str, Str --> FILE) is native(LIBC) { * }
    our sub fclose(FILE --> int) is native(LIBC) { * }
    our sub fflush(FILE --> int) is native(LIBC) { * }
    our sub puts(Str --> int) is native(LIBC) { * }
    our sub fgets(Ptr, int, FILE --> Str) is native(LIBC) { * }
    our sub fread(Ptr, size_t, size_t, FILE --> size_t) is native(LIBC) { * }
    our sub feof(FILE --> int) is native(LIBC) { * }

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

    our sub clock(--> clock_t) is native(LIBC) { * }

    our sub srand(uint) is native(LIBC) { * };
    our sub rand(--> int) is native(LIBC) { * };

    my class Array does Positional is Iterable {
        has $.type;
        has size_t $.elems;
        has CArray $.carray handles <AT-POS ASSIGN-POS>;

        method Pointer { nativecast(Pointer[$!type], $!carray) }

        method size { $!elems * sizeof($!type) }
        method at(size_t \idx) { self.Pointer.displace(idx) }

        method list { gather { take self.AT-POS($_) for ^$!elems } }
        method iterator { self }
        method reify($) { Parcel.new(self.list) }
    }

    my class ScalarArray is Array {}

    my class StructArray is Array {
        method AT-POS(size_t \idx) is rw {
            my \array = self;
            Proxy.new(
                FETCH => method () { array.at(idx).rv },
                STORE => method (\value) { array.ASSIGN-POS(idx, value) },
            );
        }

        method ASSIGN-POS(size_t \idx, \value) {
            die "Cannot assign { value.WHAT.gist }" unless value ~~ self.type;
            memmove(self.at(idx), nativecast(Ptr, value), sizeof(self.type));
        }
    }

    use MONKEY_TYPING;
    augment class Pointer {
        method to(Mu:U \type) {
            nqp::box_i(nqp::unbox_i(nqp::decont(self)), Pointer[type]);
        }

        method grab(size_t \elems) {
            my \type = self.of;
            (given nqp::unbox_s(type.REPR) {
                when 'CStruct' { StructArray }
                when 'P6int' | 'P6num' { ScalarArray }
                default { die "Unhandled REPR '$_'" }
            }).new(
                type => type,
                elems => elems,
                carray => nativecast(CArray[type], self)
            );
        }

        method displace(ptrdiff_t \offset) {
            my \type = self.of;
            Pointer.new(self + sizeof(type) * offset).to(type);
        }

        method rv { self.deref }
        method lv is rw { self.grab(1).AT-POS(0) } # HACK
    }

    class FILE is Ptr {
        method open(Str \path, Str \mode = 'r') { fopen(path, mode) }
        method close { fclose(self) }
        method flush { fflush(self) }
        method eof { feof(self) != 0 }

        method gets(Ptr() \ptr, int \count) { fgets(ptr, count, self) }
    }
}
