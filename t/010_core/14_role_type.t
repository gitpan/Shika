use strict;
use warnings;
use Test::More tests => 5;

{
    package Request::Headers::Role;
    use Shika::Role;
    has 'foo';
}

{
    package Request::Headers;
    use Shika;
    with 'Request::Headers::Role';
}

{
    package Response::Headers::Role;
    use Shika::Role;
    has 'foo';
}

{
    package Response::Headers;
    use Shika;
    with 'Response::Headers::Role';
}

{
    package Response;
    use Shika;
    use Shika::Util::TypeConstraints;

    role_type Headers => { role => 'Response::Headers::Role' };
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

eval {
    $res->headers( Request::Headers->new( foo => 'baz' ) );
};
ok $@;
