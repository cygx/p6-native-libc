use nqp;
use NativeCall;
use Native::LibC;

use MONKEY-TYPING;

my class NativeArray does Positional does Iterable {
    has Mu:U $.type;
    has int $.elems;
    has CArray $.carray handles <AT-POS ASSIGN-POS>;

    submethod BUILD(Mu:U :$!type, int :$elems, CArray :$!carray) {
        $!elems = $elems; # BUG -- no native :$! parameters
    }

    method Pointer { nativecast(Pointer[$!type], $!carray) }

    method size { $!elems * nativesizeof($!type) }
    method at(int \idx) { self.Pointer.displace(idx) }

    method iterator {
        my int $elems = $!elems;
        my \array = self;
        (class :: does Iterator {
            has int $!i = 0;
            method pull-one {
                $!i < $elems ?? array.AT-POS($!i++) !! IterationEnd
            }
        }).new
    }
}

my class ScalarArray is NativeArray {}

my class StructArray is NativeArray {
    method AT-POS(int \idx) is rw {
        my \array = self;
        Proxy.new(
            FETCH => method () { array.at(idx).rv },
            STORE => method (\value) { array.ASSIGN-POS(idx, value) },
        );
    }

    method ASSIGN-POS(int \idx, \value) {
        die "Cannot assign { value.WHAT.gist }" unless value ~~ self.type;
        libc::memmove(self.at(idx), nativecast(Pointer, value),
            nativesizeof(self.type));
    }
}

my class FuncPointer {
    has Pointer $.ptr;
    has Signature $.sig;

    method invoke(|args) { !!! }
}

augment class Pointer {
    multi method as(Signature \s) {
        FuncPointer.new(sig => s, ptr => self.as(Pointer));
    }

    multi method as(Pointer:U \type) {
        nqp::box_i(nqp::unbox_i(nqp::decont(self)), nqp::decont(type));
    }

    multi method as(Int:U) {
        nqp::unbox_i(nqp::decont(self));
    }

    method to(Mu:U \type) {
        nqp::box_i(nqp::unbox_i(nqp::decont(self)), Pointer[type]);
    }

    method grab(int \elems) {
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

    method displace(int \offset) {
        my \type = self.of;
        Pointer.new(self + nativesizeof(type) * offset).to(type);
    }

    method rv { self.deref }
    method lv is rw { self.grab(1).AT-POS(0) } # HACK

    # HACK: work around precompilation issues

    my role TypedPointer[::TValue = void] is Pointer is repr('CPointer') {
        method of() { TValue }
        # method ^name($obj) { 'Pointer[' ~ TValue.^name ~ ']' }
        method deref(::?CLASS:D \ptr:) { nativecast(TValue, ptr) }
    }

    Pointer.HOW.^can('parameterize').wrap: -> $, $, Mu:U \t {
        die "A typed pointer can only hold integers, numbers, strings, CStructs, CPointers or CArrays (not {t.^name})"
            unless t ~~ Int|Num|Bool || t === Str|void || t.REPR eq any <CStruct CUnion CPPStruct CPointer CArray>;
        my \typed := TypedPointer[t];
        typed.^inheritalize;
    }
}
