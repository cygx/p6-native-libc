all: libc.moarvm p6-libc.dll

libc.moarvm: libc.pm6 p6-libc.dll
	perl6 --target=mbc --output=$@ $<

p6-libc.dll: libc.c
	gcc -Wall -Wextra -shared -o $@ $<
