my \TEMPLATE = q:to/__END__/;
# Native::LibC [![Build Status][TRAVISIMG]][TRAVIS]

The C standard library


# Synopsis

```
    use Native::LibC <malloc fopen puts free>;

    my $buf = malloc(1024);
    my $file = fopen('LICENSE', 'r');

    loop { puts(chomp $file.gets($buf, 1024) // last) }

    $file.close;
    free($buf);
```


# Description

Provides access to the C standard library.

This is work in progress and not a finished product. Feel free to
[open a ticket][NEWTICKET] if you need a particular feature that's still
missing.


# LibC API

Overview over the `libc::` namespace, a lexical alias for `Native::LibC::`.

Anything that's missing from this list still needs to be implemented.

__API__


# Bugs and Development

Development happens at [GitHub][SOURCE]. If you found a bug or have a feature
request, use the [issue tracker][ISSUES] over there.


# Copyright and License

Copyright (C) 2015 by <cygx@cpan.org>

Distributed under the
[Boost Software License, Version 1.0](http://www.boost.org/LICENSE_1_0.txt)


[TRAVIS]:       https://travis-ci.org/cygx/p6-native-libc
[TRAVISIMG]:    https://travis-ci.org/cygx/p6-native-libc.svg?branch=v2
[SOURCE]:       https://github.com/cygx/p6-native-libc
[ISSUES]:       https://github.com/cygx/p6-native-libc/issues
[NEWTICKET]:    https://github.com/cygx/p6-native-libc/issues/new
[LICENSE]:      http://www.boost.org/LICENSE_1_0.txt
__END__

my @constants;
my @functions;
my @classes;

my @comments;
my @declarations;

my $comment;
my $id = 0;

for 'lib/Native/LibC.pm6'.IO.lines {
    next unless $_;
    $comment = /^ \s* '#|' \s+ (.+) / ?? ~$0 !! Nil;

    given $_ {
        when /^ \s* [our|multi] \s+ sub \s+ / { @functions.push($id) }
        when /^ \s* constant \s+ / { @constants.push($id) }
        when /^ \s* class \s+ / { next if / '...' /; @classes.push($id) }
        when /^ \s* method \s+ / { @classes.push($id) }
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

multi dump(@list) {
    say "{ @declarations[$_] }\n{ @comments[$_] // '' }" for @list;
}

multi dump {
    say "\n## Constants\n";
    dump @constants;

    say "\n## Functions\n";
    dump @functions;

    say "\n## Classes\n";
    dump @classes;
}

my $*OUT = open 'README.md', :w;
for TEMPLATE.lines {
    if / __API__  / { dump }
    else { .say }
}
