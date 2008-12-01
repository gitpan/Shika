use strict;
use warnings;
use Test::More tests => 4;

{
    package Response::Headers;
    use Shika;
    has 'foo';
}

{
    package Response;
    use Shika;
    use Shika::Util::TypeConstraints;

    class_type Headers => { class => 'Response::Headers' };
    coerce 'Headers' => +{
        HashRef => sub {
            $_[0] = Response::Headers->new(%{ $_[0] });
        },
    };

    has headers => (
        isa    => 'Headers',
        coerce => 1,
    );
}

my $res = Response->new(headers => { foo => 'bar' });
isa_ok($res->headers, 'Response::Headers');
is($res->headers->foo, 'bar');
$res->headers({foo => 'yay'});
isa_ok($res->headers, 'Response::Headers');
is($res->headers->foo, 'yay');
