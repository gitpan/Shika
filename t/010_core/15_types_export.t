use strict;
use warnings;
use Test::More tests => 4;

{
    package Types;
    use Shika::Util::TypeConstraints -export => [qw/ Headers /];

    subtype 'Headers' => sub { defined $_[0] && eval { $_[0]->isa('Headers') } };
    coerce 'Headers' => +{
        HashRef => sub {
            $_[0] = Headers->new(%{ $_[0] });
        },
    };
}

{
    package Headers;
    use Shika;
    has 'foo';
}

{
    package Response;
    use Shika;
    Types->import(qw/ Headers /);

    has headers => (
        isa    => 'Headers',
        coerce => 1,
    );
}

{
    package Request;
    use Shika;
    Types->import(qw/ Headers /);

    has headers => (
        isa    => 'Headers',
        coerce => 1,
    );
}

my $res = Response->new(headers => { foo => 'bar' });
is($res->headers->foo, 'bar');
$res->headers({foo => 'yay'});
is($res->headers->foo, 'yay');

my $req = Request->new(headers => { foo => 'bar' });
is($req->headers->foo, 'bar');
$req->headers({foo => 'yay'});
is($req->headers->foo, 'yay');

