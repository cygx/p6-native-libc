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

class MyScalar {
    has $!carray;

    method FETCH { $!carray.AT-POS(0) }
    method STORE(\value) { $!carray.ASSIGN-POS(0, value) }

    method Pointer { nativecast Pointer[$!carray.of], $!carray }

    submethod BUILD(:$!carray) {}

    method from(MyScalar:U: Pointer:D \ptr) {
        my $self := nqp::create(MyScalar);
        my $carray := nativecast(CArray[ptr.of], ptr);
        nqp::bindattr($self, MyScalar, '$!carray', $carray);
        $self;
    }

    method new(Mu:U \type, \value = Nil) {
        my $carray := CArray[type].new;
        $carray[0] = value // do given ~type.REPR {
            when 'P6int' { 0 }
            when 'P6num' { 0e0 }
            when 'CPointer' { type }
            default { die "Unhandled REPR '$_'" }
        }

        my $self := nqp::create(MyScalar);
        nqp::bindattr($self, MyScalar, '$!carray', $carray);
        $self;
    }
}

class MyStruct {
    has $!struct;

    method FETCH { $!struct }
    method STORE(\value) { assign $!struct.WHAT, $!struct, value }

    method Pointer { nativecast Pointer[$!struct.WHAT], $!struct }

    submethod BUILD(:$!struct) {}

    method from(Pointer:D \ptr) {
        given ~ptr.of.REPR {
            die "Unhandled REPR '$_'"
                unless $_ eq 'CStruct'
        }

        my $self := nqp::create(MyStruct);
        nqp::bindattr($self, MyStruct, '$!struct', nativecast(ptr.of, ptr));
        $self;
    }

    method new(Mu:U \type, |c) {
        my $self := nqp::create(MyStruct);
        nqp::bindattr($self, MyStruct, '$!struct', type.new(|c));
        $self;
    }
}

{
    use nqp:from<NQP>;
    EVAL q:to/__END__/, :lang<nqp>;

    sub FETCH($cont) {
        my $var := nqp::p6var($cont);
        nqp::decont(nqp::findmethod($var,'FETCH')($var));
    }

    sub STORE($cont, $value) {
        my $var := nqp::p6var($cont);
        nqp::findmethod($var, 'STORE')($var, $value);
    }

    my %pair := nqp::hash(
        'fetch', nqp::getstaticcode(&FETCH),
        'store', nqp::getstaticcode(&STORE)
    );

    nqp::setcontspec(MyScalar, 'code_pair', %pair);
    nqp::setcontspec(MyStruct, 'code_pair', %pair);

    __END__
}

class MyArray does Positional does Iterable {
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

my class ScalarArray is MyArray {
    method AT-POS(uint \idx) is rw { MyScalar.from(self.at(idx)) }
}

my class StructArray is MyArray {
    method AT-POS(uint \idx) is rw {
        MyStruct.from(self.at(idx));
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
            when 'CStruct' { MyStruct }
            when 'P6int' | 'P6num' | 'CPointer' { MyScalar }
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
