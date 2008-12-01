package Shika::Role;
use strict;
use warnings;
use Shika::Util;

sub import {
    my $pkg = caller(0);
    strict->import;
    warnings->import;

    my $meta = +{
        requires => [],
        has      => [],
        modifier => {},
        role     => [],
    };

    no strict 'refs';
    *{"$pkg\::requires"} = \&_requires;
    *{"$pkg\::has"}      = \&_has;
    *{"$pkg\::with"}     = \&_with;
    *{"$pkg\::before"}   = \&_before;
    *{"$pkg\::after"}    = \&_after;
    *{"$pkg\::around"}   = \&_around;
    *{"$pkg\::meta"}     = sub { $meta };
}

sub _with {
    my $pkg = caller(0);
    my @roles = @_;
    Shika::Role::apply_roles($pkg, @roles);
}

sub apply_roles {
    my ($target, @roles) = @_;

    for my $role (@roles) {
        my $alias = {};
        if (ref $role eq 'HASH') {
            $alias = $role->{alias};
            $role  = $role->{role};
        }
        Shika::Util::load_class($role) unless $role->can('meta');
        next unless $role->can('meta');

        Shika::Util::copy_functions($role => $target, $alias);
        unshift @{$target->meta->{has}}, @{ $role->meta->{has} };

        # install method modifiers
        while (my($name, $modifiers) = each %{ $role->meta->{modifier} }) {
            my $target_modifier = _init_modifier($target, $name);
            for my $type (qw/ before after around /) {
                push @{ $target_modifier->{$type} }, @{ $modifiers->{$type} };
            }
        }

        # copy subtype/coerce
        require Shika::Util::TypeConstraints;
        Shika::Util::TypeConstraints::copy_types($role, $target, '-all');

        push @{ $target->meta->{role} }, $role;
    }
}

sub _requires {
    my $pkg = caller(0);
    push @{ $pkg->meta->{requires} }, [ @_ ];
}

sub _has {
    my ($name, %attr) = @_;
    my $pkg = caller(0);
    push @{ $pkg->meta->{has} }, {name => $name, attr => \%attr};
}


sub _init_modifier {
    my($pkg, $name) = @_;
    my $code = $pkg->can($name);
    $pkg->meta->{modifier}->{$name} ||= +{
        around       => [],
        before       => [],
        after        => [],
    };
}

{
    no strict 'refs';
    for my $_type (qw/before after around/) {
        my $type = $_type;
        *{"_${type}"} = sub {
            my ($name, $code) = @_;
            my $pkg = caller(0);
            my $modifier = _init_modifier($pkg, $name);
            push @{ $modifier->{$type} }, $code;
        };
    }
}

1;

__END__

=head1 NAME

Shika::Role - the role class of Shika

=head1 SYNOPSIS

    package MyRole;
    use Shika::Role;

=head1 EXPORTED FUNCTIONS

=over 4

=item has

create accessors.

=item requires(@methods)

Roles can require that certain methods are implemented by any class
which "does" the role.

=item with(@roles)

same as Moose::with(@roles).

=item before $name => sub { }

=item after $name => sub { }

=item around $name => sub { }

method modifiers.

=back

=cut
