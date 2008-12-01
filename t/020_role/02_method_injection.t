use strict;
use warnings;
use Test::More tests => 1;

{
    package Bar;
    use Shika::Role;

    sub baz {
        'ok';
    }
}

{
    package Foo;
    use Shika;
    with 'Bar';
}

my $f = Foo->new;
is $f->baz, 'ok';

