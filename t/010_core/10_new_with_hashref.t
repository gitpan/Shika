use strict;
use warnings;
use Test::More tests => 1;

{
    package Foo;
    use Shika;
    has 'bar';
}

my $f = Foo->new({bar => 'baz'});
is $f->bar, 'baz';

