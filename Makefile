PERL6   = perl6
CC      = gcc
CFLAGS  = -Wall -Wextra -shared
DLL     = p6-libc.so
OUT     = -o
RM      = rm -f
GARBAGE = libc.moarvm $(DLL)

all: libc.moarvm $(DLL)
clean:
	-$(RM) $(GARBAGE)

libc.moarvm: libc.pm6 $(DLL)
	$(PERL6) --target=mbc --output=$@ libc.pm6

$(DLL): libc.c
	$(CC) libc.c $(CFLAGS) $(OUT)$@
