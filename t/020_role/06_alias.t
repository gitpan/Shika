use strict;
use warnings;
use Test::More tests => 6;

{
    package B3;
    use Shika::Role;
    has 'hoge';
    sub baz {
        'ok';
    }
}

{
    package B2;
    use Shika::Role;
    with { role => 'B3', alias => { baz => 'aliased' } };
    sub baz { 'alive' }
    sub alias_me { 'blah blah' }
}

{
    package B1;
    use Shika;
    with { role => 'B2', alias => { alias_me => 'aliased_you' } };
}

my $f = B1->new('hoge' => 'fuga');
isa_ok $f, 'B1';
is $f->aliased, 'ok';
is $f->baz,  'alive';
is $f->hoge, 'fuga';
ok !$f->can('alias_me');
is $f->aliased_you, 'blah blah';

