@nmake.exe /NOLOGO RM="del" DLL="p6-libc.dll" CC="cl" CFLAGS="/link /DLL" OUT="/OUT:" GARBAGE="libc.moarvm libc.obj p6-libc.dll p6-libc.lib p6-libc.exp" %*
