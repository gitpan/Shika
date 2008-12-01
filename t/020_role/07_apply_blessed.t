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
}

my $f = Foo->new;
Shika::apply_roles($f, 'Bar');
is $f->baz, 'ok';

