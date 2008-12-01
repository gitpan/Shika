use strict;
use warnings;
use Test::More tests => 6;

my $i = 0;
{
    package Foo;
    use Shika;

    sub bar {
        main::is $i++, 0;
        'ok';
    }

    after bar => sub {
        main::is $_[1], 1;
        main::is $i++, 1;
    };

    after bar => sub {
        main::is $_[1], 1;
        main::is $i++, 2;
    };

}

my $f = Foo->new;
is $f->bar(1), 'ok';
