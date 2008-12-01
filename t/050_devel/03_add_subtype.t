use strict;
use warnings;
use Test::More tests => 8;
BEGIN { $ENV{SHIKA_DEVEL} = 1 };

{
    package Foo;
    use Shika;
    use Shika::Util::TypeConstraints;

    subtype 'Yappo' => sub {
        defined $_[0] && $_[0] eq 'yappo';
    };

    has 'bar' => ( isa => 'Yappo' );
}

eval {
    Foo->new( bar => 'baz' );
};
ok $@;

eval {
    isa_ok(Foo->new( bar => 'yappo' ), 'Foo');
};
ok !$@;


my $f = Foo->new;
eval {
    $f->bar([]);
};
ok $@;

eval {
    $f->bar('yappo');
};
ok !$@;
is $f->bar, 'yappo';

eval {
    $f->bar(undef);
};
ok $@;
is $f->bar, 'yappo';
