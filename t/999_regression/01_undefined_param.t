use strict;
use warnings;
use Test::More tests => 1;

{
    package Foo;
    use Shika;
    has foo => (
        requires => 1,
    );
}

my $f = Foo->new(foo => undef);
is $f->foo, undef;

