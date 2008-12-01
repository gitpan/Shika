use strict;
use warnings;
use Test::More tests => 2;

{
    package Bar;
    use Shika::Role;

    has yay => ();
    has def => (
        default => 'ault'
    );
}

{
    package Foo;
    use Shika;
    with 'Bar';
}

my $f = Foo->new(yay => 'yo');
is $f->yay, 'yo';
is $f->def, 'ault';

