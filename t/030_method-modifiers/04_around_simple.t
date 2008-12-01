use strict;
use warnings;
use Test::More tests => 11;

my $i = 0;
{
    package Foo;
    use Shika;

    sub bar {
        main::is $i++, 2;
        main::is $_[1], 3;
        $_[1]+1;
    }

    around bar => sub {
        my $next = shift;
        main::is $_[1], 1;
        main::is $i++, 0;
        my $ret = $next->($_[0], $_[1] + 1);
        main::is $ret, 5;
        main::is $i++, 4;
        $ret+1;
    };

    around bar => sub {
        my $next = shift;
        main::is $_[1], 2;
        main::is $i++, 1;
        my $ret = $next->($_[0], $_[1] + 1);
        main::is $ret, 4;
        main::is $i++, 3;
        $ret+1;
    };

}

my $f = Foo->new;
is $f->bar(1), 6;
