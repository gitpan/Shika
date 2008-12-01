use strict;
use warnings;
use Test::More tests => 28;

{
    package Parent;
    use Shika;
    has bom => (
        lazy    => 1,
        default => sub { 4 },
    );
    has baz => (
        lazy    => 1,
        default => 2,
    );
    has class => (
        lazy => 1,
        default => sub { ref $_[0] }
    );
}

{
    package Foo;
    use Shika;
    extends 'Parent';
    has bar => (
        lazy    => 1,
        default => sub { 3 },
    );
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

{
    my $f = Foo->new(baz => 5);
    is $f->class, 'Foo';
}

