@nmake.exe /NOLOGO RM="rm-f" DLL="p6-libc.dll" CC="cl" CFLAGS="/link /DLL" OUT="/OUT:" GARBAGE="libc.obj p6-libc.lib p6-libc.exp" %*
