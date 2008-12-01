BEGIN { $ENV{SHIKA_DEVEL} = 1 }
use strict;
use warnings;
use Test::More tests => 3;

{
    package Headers;
    use Shika;
    has 'foo';
}

{
    package Response::Headers;
    use Shika;
    extends 'Headers';
}

{
    package Response;
    use Shika;

    has headers => (
        isa    => 'Headers',
    );
}

my $res = Response->new(headers => Response::Headers->new(foo => 'bar'));
is($res->headers->foo, 'bar');
$res->headers(Response::Headers->new(foo => 'yay'));
is($res->headers->foo, 'yay');

$res->headers(Headers->new(foo => 'YATTA'));
is($res->headers->foo, 'YATTA');
