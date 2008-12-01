use strict;
use warnings;
use Test::More tests => 1;

{
    package Bar;
}

{
    package Foo;
    use Shika;
    extends 'Bar';
}

my $f = Foo->new(bar => 'baz');
ok $f->isa('Bar');

