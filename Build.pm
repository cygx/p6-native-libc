use Panda::Builder;
class Build is Panda::Builder;

method build($workdir) {
    my $kernel = $*VM.config<os> // $*KERNEL.name;
    die "libc: Build receipe '$kernel' failed" unless shell do given $kernel {
        when 'win32'   { "cd \"$workdir\" && nmake.bat PERL6=$*EXECUTABLE" }
        when 'mingw32' { "cd \"$workdir\" && gmake.bat PERL6=$*EXECUTABLE" }
        when 'linux'   { "make -C '$workdir' PERL6=$*EXECUTABLE" }
        default { die "libc: Unsupported kernel '$_'" }
    }
}
