# TITLE

libc

# SYNOPSIS

```
    use libc;

    my $buf = libc::malloc(1024);
    my $file = libc::fopen('LICENSE', 'r');

    loop { libc::puts(chomp $file.gets($buf, 1024) // last) }

    $file.close;
    libc::free($buf);
```


# DESCRIPTION

Provides access to the C standard library. Also monkey-patches the
NativeCall Pointer class, adding an `rw` accessor as well as an iterable
wrapper over CArray.

The interface is preliminary and undocumented.

See [API.md](API.md) for a quick overview over what parts of the standard
library are implemented.


# BUILDING

The file `libc.c` needs to be compiled into a shared library named
`p6-libc.*`.

You can try to use panda or the Makefile, but no guarantees.

On Windows, use the wrapper batch scripts for MSVC nmake or MinGW gmake.


# LICENSE

Boost Software License, Version 1.0
