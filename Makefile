PERL6   = perl6
CC      = gcc
CFLAGS  = -Wall -Wextra -shared
DLL     = p6-libc.so
OUT     = -o
RM      = rm -f
GEN     = libc.moarvm $(DLL)
GARBAGE =

all: $(GEN) INDEX.md
clean:
	-$(RM) $(GEN) $(GARBAGE)

libc.moarvm: libc.pm6 $(DLL)
	$(PERL6) --target=mbc --output=$@ libc.pm6

$(DLL): libc.c
	$(CC) libc.c $(CFLAGS) $(OUT)$@

INDEX.md: index.p6 libc.pm6
	$(PERL6) index.p6 > $@
