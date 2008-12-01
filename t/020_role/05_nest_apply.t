use strict;
use warnings;
use Test::More tests => 2;

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
    with 'B3';
}

{
    package B1;
    use Shika;
    with 'B2';
}

my $f = B1->new('hoge' => 'fuga');
is $f->baz, 'ok';
is $f->hoge, 'fuga';

