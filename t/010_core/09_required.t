use strict;
use warnings;
use Test::More tests => 2;

{
    package Foo;
    use Shika;
    has 'bar' => (required => 1);
}

eval { Foo->new(bar => 'baz') };
ok !$@;

eval { Foo->new() };
ok $@;

