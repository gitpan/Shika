use strict;
use warnings;
use Test::More tests => 4;

{
    package Headers;
    use Shika;
    has 'foo';
}

{
    package Response;
    use Shika;
    use Shika::Util::TypeConstraints;

    subtype 'Headers' => sub { defined $_[0] && eval { $_[0]->isa('Headers') } };
    coerce 'Headers' => +{
        HashRef => sub {
            $_[0] = Headers->new(%{ $_[0] });
        },
    };

    has headers => (
        isa    => 'Headers',
        coerce => 1,
    );
    has lazy_build_coerce_headers => (
        isa    => 'Headers',
        coerce => 1,
        lazy_build => 1,
    );
    sub _build_lazy_build_coerce_headers {
        Headers->new(foo => 'laziness++')
    }
    has lazy_coerce_headers => (
        isa    => 'Headers',
        coerce => 1,
        lazy => 1,
        default => sub { Headers->new(foo => 'laziness++') }
    );
}

my $r = Response->new(headers => { foo => 'bar' });
is($r->headers->foo, 'bar');
$r->headers({foo => 'yay'});
is($r->headers->foo, 'yay');
is($r->lazy_coerce_headers->foo, 'laziness++');
is($r->lazy_build_coerce_headers->foo, 'laziness++');

