use strict;
use warnings;
use Test::More tests => 1;

{
    package Foo;
    use Shika;
}

isa_ok(Foo->new(), 'Foo');
