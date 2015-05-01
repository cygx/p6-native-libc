my @constants;
my @functions;
my @classes;

my @comments;
my @declarations;

my $comment;
my $id = 0;

for 'libc.pm6'.IO.lines {
    next unless $_;
    $comment = /^ \s* '#|' \s+ (.+) / ?? ~$0 !! Nil;

    given $_ {
        when /^ [our|multi] \s+ sub \s+ / { @functions.push($id) }
        when /^ constant \s+ / { @constants.push($id) }
        when /^ class \s+ / { next if / '...' /; @classes.push($id) }
        default { next }
    }

    @comments[$id] = $comment;
    @declarations[$id] = $_ ~ do given .chomp.substr(*-1) {
        when '(' { ' * );' }
        when '{' { ' * }' }
        default { '' }
    }

    ++$id;
}

sub dump(@list) {
    say "    { @declarations[$_] }\n{ @comments[$_] // '' }" for @list;
}

say q:to/__END__/;
    # Index
    
    Overview over the `libc::` namespace.
    __END__

say "\n## Constants\n";
dump @constants;

say "\n## Functions\n";
dump @functions;

say "\n## Classes\n";
dump @classes;
