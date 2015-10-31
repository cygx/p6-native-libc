use nqp;
use MONKEY-TYPING;

use NativeCall;

sub assign(Mu:U \type, Mu:D \dest, Mu:D \value) {
    use Native::LibC <memmove>;

    die "Cannot assign { value.WHAT.gist } to { type.gist }"
        unless value ~~ type;

    memmove(nativecast(Pointer, dest), nativecast(Pointer, value), 
        nativesizeof(type));
}

class Native::Scalar is Proxy {
    method !make(CArray \it) {
        self.new(
            FETCH => method () { it.AT-POS(0) },
            STORE => method (\value) { it.ASSIGN-POS(0, value) },
        );
    }

    method from(Pointer:D \ptr) {
        self!make(nativecast CArray[ptr.of], ptr);
    }

    method create(Mu:U \type) {
        my \array = CArray[type].new;
        array[0] = do given ~type.REPR {
            when 'P6int' { 0 }
            when 'P6num' { 0e0 }
            when 'CPointer' { type }
            default { die "Unhandled REPR '$_'" }
        }
        self!make(array);
    }
}

class Native::Struct is Proxy {
    has $.foo = 42;

    method !make(\it) {
        die "Unhandled REPR '{ it.REPR }'"
            unless it.REPR eq 'CStruct';

        self.new(
            FETCH => method () { it },
            STORE => method (\value) { assign(it.WHAT, it, value) },
        );
    }

    method from(Pointer:D \ptr) {
        self!make(nativecast ptr.of, ptr);
    }

    method create(Mu:U \type, |c) {
        self!make(type.new(|c));
    }
}

class Native::Array does Positional does Iterable {
    has Mu:U $.type;
    has uint $.elems;
    has CArray $.carray handles <ASSIGN-POS>;

    submethod BUILD(Mu:U :$!type, uint :$elems, CArray :$!carray) {
        $!elems = $elems; # BUG -- no native :$! parameters
    }

    method Pointer { nativecast(Pointer[$!type], $!carray) }

    method size { $!elems * nativesizeof($!type) }
    method at(uint \idx) { self.Pointer.displace(idx) }

    method iterator {
        my uint $elems = $!elems;
        my \array = self;
        (class :: does Iterator {
            has uint $!i = 0;
            method pull-one {
                $!i < $elems ?? array.AT-POS($!i++) !! IterationEnd
            }
        }).new
    }
}

my class ScalarArray is Native::Array {
    method AT-POS(uint \idx) is rw { Native::Scalar.from(self.at(idx)) }
}

my class StructArray is Native::Array {
    method AT-POS(uint \idx) is rw {
        Native::Struct.from(self.at(idx));
    }

    method ASSIGN-POS(uint \idx, \value) {
        assign self.type, self.at(idx), value;
    }
}

my class UnionArray is StructArray {}

augment class Pointer {
    my class FuncPointer {
        has Pointer $.ptr;
        has Signature $.sig;

        method invoke(|args) { !!! }
    }

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

    method grab(uint \elems) {
        my \type = self.of;
        (given nqp::unbox_s(type.REPR) {
            when 'CStruct' { StructArray }
            when 'CUnion' { UnionArray }
            when 'P6int' | 'P6num' | 'CPointer' { ScalarArray }
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
    method lv is rw {
        .from(self) given do given ~self.of.REPR {
            when 'CStruct' { Native::Struct }
            when 'P6int' | 'P6num' | 'CPointer' { Native::Scalar }
            default { die "Unhandled REPR '$_'" }
        }
    }

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
