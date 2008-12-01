use strict;
use warnings;
use Test::More tests => 1;
use lib 't/020_role/lib/';

{
    package Bar;
    use Shika;
    with 'Foo';
}

my $f = Bar->new;
is $f->hello, 'world';

