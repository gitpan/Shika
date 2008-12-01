use strict;
use warnings;
use Test::More tests => 8;

my $i = 0;
{
    package Foo;
    use Shika;

    sub bar {
        main::is $i++, 0;
        main::is $_[1], 1;
        $_[1]+1;
    }
    sub baz {
        main::is $i++, 1;
        main::is $_[1], 3;
        $_[1]+1;
    }

    before [qw/bar baz/] => sub {
        main::ok $_[1];
    };
}

my $f = Foo->new;
is $f->bar(1), 2, 'ret value of bar';
is $f->baz(3), 4;
