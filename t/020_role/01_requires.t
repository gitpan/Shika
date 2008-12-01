use strict;
use warnings;
use Test::More tests => 1;

{
    package Bar;
    use Shika::Role;

    requires 'baz';
}

{
    package Foo;
    use Shika;
    with 'Bar';
    sub baz {
        'ok';
    }
}

my $f = Foo->new;
is $f->baz, 'ok';

