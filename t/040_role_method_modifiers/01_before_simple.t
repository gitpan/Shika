use strict;
use warnings;
use Test::More tests => 6;

my $i = 0;
{
    package Baz;
    use Shika::Role;

    before bar => sub {
        main::is $_[1], 1;
        main::is $i++, 1;
    };

    before bar => sub {
        main::is $_[1], 1;
        main::is $i++, 0;
    };
}
{
    package Foo;
    use Shika;
    with 'Baz';

    sub bar {
        main::is $i++, 2;
        'ok';
    }
}

my $f = Foo->new;
is $f->bar(1), 'ok';
