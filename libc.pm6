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
        method eof { feof(self) != 0 }

        method gets(Ptr() \ptr, int \count) { fgets(ptr, count, self) }
    }
}
