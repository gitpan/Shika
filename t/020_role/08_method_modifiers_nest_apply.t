use strict;
use warnings;
use Test::More tests => 17;

my $i = 0;
{
    package B3;
    use Shika::Role;
    has 'hoge';
    sub baz {
        'ok';
    }

    before x => sub {
        main::is $i++, 1;
    };
    after x => sub {
        main::is $i++, 7;
    };
    around x => sub {
        my($next, $self, $val) = @_;
        main::is $i++, 2;
        main::is $val, 10;
        my $ret = $next->($self, $val+1);
        main::is $ret, 14;
        main::is $i++, 6;
        $ret+1;
    };
}

{
    package B2;
    use Shika::Role;
    with 'B3';

    before x => sub {
        main::is $i++, 0;
    };
    after x => sub {
        main::is $i++, 8;
    };
    around x => sub {
        my($next, $self, $val) = @_;
        main::is $i++, 3;
        main::is $val, 11;
        my $ret = $next->($self, $val+1);
        main::is $ret, 13;
        main::is $i++, 5;
        $ret+1;
    };
}

{
    package B1;
    use Shika;
    with 'B2';

    sub x {
        my($self, $v) = @_;
        main::is $i++, 4;
        main::is $v, 12;
        $v+1;
    }
}

my $f = B1->new('hoge' => 'fuga');
is $f->x(10), 15;
is $f->baz, 'ok';
is $f->hoge, 'fuga';

