use strict;
use warnings;
use Test::More tests => 11;
BEGIN { $ENV{SHIKA_DEVEL} = 1 };

{
    package Boo;
    use Shika;
}

{
    package Foo;
    use Shika;
    has 'bar' => ( isa => 'HashRef' );
    has 'baz' => ( isa => 'Boo' );
}

eval {
    Foo->new( bar => 1 );
};
ok $@;

eval {
    Foo->new( baz => 1 );
};
ok $@;

eval {
    Foo->new( bar => +{}, baz => 1 );
};
ok $@;

eval {
    Foo->new( bar => 1, baz => Boo->new );
};
ok $@;

eval {
    Foo->new( bar => +{}, baz => Boo->new );
};
ok !$@;

eval {
    Foo->new( bar => +{} );
};
ok !$@;

eval {
    Foo->new( baz => Boo->new );
};
ok !$@;

my $f = Foo->new;
eval { $f->bar(1) };
ok $@;

eval { $f->baz(1) };
ok $@;

eval { $f->bar(+{}) };
ok !$@;

eval { $f->baz(Boo->new) };
ok !$@;
