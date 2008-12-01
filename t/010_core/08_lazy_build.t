use strict;
use warnings;
use Test::More tests => 27;

{
    package Parent;
    use Shika;
    has bom => (
        lazy_build => 1,
    );
    has baz => (
        lazy_build => 1,
    );

    sub _build_bom { 4 }
    sub _build_baz { 2 }
}

{
    package Foo;
    use Shika;
    extends 'Parent';
    has bar => (
        lazy_build => 1,
    );

    sub _build_bar { 3 }
}

use Data::Dumper;
{
    my $f = Foo->new();
    ok !$f->{bar};
    ok !$f->{bom};
    ok !$f->{baz};
    is $f->bar, 3;
    is $f->bom, 4;
    is $f->baz, 2;
    is $f->{bar}, 3;
    is $f->{bom}, 4;
    is $f->{baz}, 2;
}

{
    my $f = Foo->new(bar => 4);
    is $f->{bar}, 4;
    ok !$f->{bom};
    ok !$f->{baz};
    is $f->bar, 4;
    is $f->bom, 4;
    is $f->baz, 2;
    is $f->{bar}, 4;
    is $f->{bom}, 4;
    is $f->{baz}, 2;
}

{
    my $f = Foo->new(baz => 5);
    ok !$f->{bar};
    ok !$f->{bom};
    is $f->{baz}, 5;
    is $f->bar, 3;
    is $f->bom, 4;
    is $f->baz, 5;
    is $f->{bar}, 3;
    is $f->{bom}, 4;
    is $f->{baz}, 5;
}

