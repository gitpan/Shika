use strict;
use warnings;
use Test::More tests => 8;

{
    package Response::Headers;
    use Shika;
    has 'foo';
}
{
    package Request::Headers;
    use Shika;
    has 'foo';
}

{
    package Response;
    use Shika;
    use Shika::Util::TypeConstraints;

    subtype 'Headers' => sub { defined $_[0] && eval { $_[0]->isa('Response::Headers') } };
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

{
    package Request;
    use Shika;
    use Shika::Util::TypeConstraints;

    subtype 'Headers' => sub { defined $_[0] && eval { $_[0]->isa('Request::Headers') } };
    coerce 'Headers' => +{
        HashRef => sub {
            $_[0] = Request::Headers->new(%{ $_[0] });
        },
    };

    has headers => (
        isa    => 'Headers',
        coerce => 1,
    );
}

{
    package Response;
    subtype 'Headers' => sub { defined $_[0] && eval { $_[0]->isa('Response::Headers') } };
    coerce 'Headers' => +{
        HashRef => sub {
            $_[0] = Response::Headers->new(%{ $_[0] });
        },
    };
}

my $req = Request->new(headers => { foo => 'bar' });
isa_ok($req->headers, 'Request::Headers');
is($req->headers->foo, 'bar');
$req->headers({foo => 'yay'});
isa_ok($req->headers, 'Request::Headers');
is($req->headers->foo, 'yay');

my $res = Response->new(headers => { foo => 'bar' });
isa_ok($res->headers, 'Response::Headers');
is($res->headers->foo, 'bar');
$res->headers({foo => 'yay'});
isa_ok($res->headers, 'Response::Headers');
is($res->headers->foo, 'yay');
