PERL6   = perl6
PROVE   = prove
CC      = gcc
CFLAGS  = -Wall -Wextra -shared
DLLEXT  = so
DLL     = p6-native-libc.$(DLLEXT)
OUT     = -o
RM      = rm -f
GEN     = blib/Native/LibC.pm6.moarvm $(DLL)
GARBAGE =

all: $(GEN) API.md

dll: $(DLL)

clean:
	$(RM) $(GEN) $(GARBAGE)

test: $(GEN)
	$(PROVE) -e "$(PERL6) -Iblib" t

blib/Native/LibC.pm6.moarvm: lib/Native/LibC.pm6 $(DLL)
	$(PERL6) --target=mbc --output=$@ lib/Native/LibC.pm6

$(DLL): p6-native-libc.c
	$(CC) p6-native-libc.c $(CFLAGS) $(OUT)$@

API.md: api.p6 lib/Native/LibC.pm6
	$(PERL6) api.p6 > $@
