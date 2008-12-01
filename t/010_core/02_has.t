use strict;
use warnings;
use Test::More tests => 3;

{
    package Foo;
    use Shika;
    has 'bar';
}

my $f = Foo->new(bar => 'baz');
is $f->bar, 'baz';
is $f->bar('ya'), 'ya';
is $f->bar, 'ya';
