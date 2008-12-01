use strict;
use warnings;
use Test::More tests => 1;

{
    package Bar;
    use Shika;
    has 'yay';
}

{
    package Foo;
    use Shika;
    has bar => (
        default => sub { Bar->new(yay => 'default') },
        handles => [qw/yay/],
    );
    sub BUILD {
        my ($self, $params) = @_;
        $self->yay($params->{yay});
    }
}

my $f = Foo->new(yay => 'wow');
is $f->bar->yay, 'wow';

