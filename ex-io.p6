use lib 'blib';
use libc;

my $buf = libc::malloc(1024);
my $file = libc::fopen('ex-io.p6', 'r');
loop { libc::puts(chomp $file.gets($buf, 1024) // last) }
