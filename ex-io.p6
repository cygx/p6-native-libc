use Native::LibC <malloc fopen puts>;

my $buf = malloc(1024);
my $file = fopen('ex-io.p6', 'r');
loop { puts(chomp $file.gets($buf, 1024) // last) }
