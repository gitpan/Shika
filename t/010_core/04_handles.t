use strict;
use warnings;
use Test::More tests => 3;

{
    package Bar;
    use Shika;

    sub yay {
        my $self = shift;
        "yay " . join(", ", @_)
    }
}

{
    package Foo1;
    use Shika;
    has bar => (
        handles => ['yay'],
    );
}

{
    package Foo2;
    use Shika;
    has bar => (
        handles => 'yay',
    );
}

{
    package Foo3;
    use Shika;
    has bar => (
        handles => { doo => 'yay' },
    );
}

{
    my $f = Foo1->new(bar => Bar->new());
    is $f->yay('hoge', 'fuga'), 'yay hoge, fuga';
}

{
    my $f = Foo2->new(bar => Bar->new());
    is $f->yay('hoge', 'fuga'), 'yay hoge, fuga';
}

{
    my $f = Foo3->new(bar => Bar->new());
    is $f->doo('hoge', 'fuga'), 'yay hoge, fuga';
}

