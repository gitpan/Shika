use strict;
use warnings;
use Test::More tests => 1;


{
    package Bar;
    use Shika::Role;
    with 'Rougai';

    has foo => (
        isa => 'Int',
    );
}

{
    package Foo;
    use Shika;
    with 'Bar';
    has '+foo' => (
        default => sub {
            'ok'
        },
    );
}

my $f = Foo->new;
is $f->foo, 'ok';

