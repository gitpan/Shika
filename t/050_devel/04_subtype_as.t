use strict;
use warnings;
use Test::More tests => 1;
BEGIN { $ENV{SHIKA_DEVEL} = 1 };

{
    package Boo;
    use Shika;
    use Shika::Util::TypeConstraints;

    subtype Handler => {as => 'CodeRef'};
    coerce Handler => +{
        Str => sub { $_[0] = \&{$_[0]} }
    };

    has 'handler' => (
        isa => 'Handler',
        coerce => 1,
    );
}

sub foo { 'ok' }

my $boo = Boo->new(
    handler => 'main::foo',
);
is $boo->handler()->(), 'ok';

