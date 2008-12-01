use strict;
use warnings;
use Test::More tests => 9;

{
    package Parent;
    use Shika;
    has bom => (
        default => sub { 4 },
    );
    has baz => (
        default => 2,
    );
}

{
    package Foo;
    use Shika;
    extends 'Parent';
    has bar => (
        default => sub { 3 },
    );
}

{
    my $f = Foo->new();
    is $f->bar, 3;
    is $f->bom, 4;
    is $f->baz, 2;
}

{
    my $f = Foo->new(bar => 4);
    is $f->bar, 4;
    is $f->bom, 4;
    is $f->baz, 2;
}

{
    my $f = Foo->new(baz => 5);
    is $f->bar, 3;
    is $f->bom, 4;
    is $f->baz, 5;
}
