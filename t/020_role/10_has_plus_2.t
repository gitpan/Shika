use strict;
use warnings;
use Test::More tests => 4;

{
    package Foo;
    use Shika::Role;

    has def => (
        default => 'ault'
    );
}

{
    package Bar;
    use Shika;
    with 'Foo';
}

{
    package Baz;
    use Shika;
    with 'Foo';

    has '+def' => (
        default => 'BAZ',
    );
}

my $bar = Bar->new;
is $bar->def, 'ault';

my $baz = Baz->new;
is $baz->def, 'BAZ';


eval {
    package Boo;
    use Shika;
    has '+def' => (
        default => 'BAZ',
    );
};
ok $@;
like $@, qr/Cannot overwrite def.Boo doesn't have a def/;
