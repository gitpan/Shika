use strict;
use warnings;
use Test::More tests => 10;
BEGIN { $ENV{SHIKA_DEVEL} = 1 };

{
    package Foo;
    use Shika;
    has 'bar' => ( isa => 'Str | Undef' );
}

eval {
    Foo->new( bar => +{} );
};
ok $@;

eval {
    isa_ok(Foo->new( bar => undef ), 'Foo');
};
ok !$@;

eval {
    isa_ok(Foo->new( bar => 'foo' ), 'Foo');

};
ok !$@;


my $f = Foo->new;
eval {
    $f->bar([]);
};
ok $@;

eval {
    $f->bar('hoge');
};
ok !$@;
is $f->bar, 'hoge';

eval {
    $f->bar(undef);
};
ok !$@;
ok !$f->bar;
