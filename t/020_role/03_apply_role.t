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
    package Chars;
    use Shika;
}

Shika::apply_roles('Chars', 'Bar');
my $f = Chars->new;
is $f->baz, 'ok';

