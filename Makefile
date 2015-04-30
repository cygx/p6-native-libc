all: libc.moarvm p6-libc.dll

libc.moarvm: libc.pm6
	perl6 --target=mbc --output=$@ $<

p6-libc.dll: libc.c
	gcc -shared -o $@ $<
