PERL6    = perl6
PROVE    = prove
CC       = gcc
CFLAGS   = -Wall -Wextra
DLLFLAGS = -fPIC -shared
DLLEXT   = so
DLL      = p6-native-libc.$(DLLEXT)
OUT      = -o
RM       = rm -f
MV       = mv
GEN      = blib/Native/LibC.pm6.moarvm blib/Native/MonkeyPatch.pm6.moarvm $(DLL)
GARBAGE  =

all: $(GEN) README.md

dll: $(DLL)

clean:
	$(RM) $(GEN) $(GARBAGE)

test: $(GEN)
	$(PROVE) -e "$(PERL6) -Iblib" t

blib/Native/LibC.pm6.moarvm: lib/Native/LibC.pm6 $(DLL)
	$(PERL6) --target=mbc --output=$@ lib/Native/LibC.pm6

blib/Native/MonkeyPatch.pm6.moarvm: lib/Native/MonkeyPatch.pm6 blib/Native/LibC.pm6.moarvm
	$(PERL6) -Iblib --target=mbc --output=$@ lib/Native/MonkeyPatch.pm6

$(DLL): build/p6-native-libc.c
	$(CC) build/p6-native-libc.c $(CFLAGS) $(DLLFLAGS) $(OUT)$@

README.md: build/README.md.in build/README.md.p6 lib/Native/LibC.pm6
	$(PERL6) build/$@.p6 <build/$@.in >$@.tmp
	$(MV) $@.tmp $@
