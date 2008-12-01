package Shika::Devel;
use strict;
use warnings;

use Carp ();

use Shika::Util;
use Shika::Util::TypeConstraints;

sub import {
    for my $name (@{ Shika::Util::get_functions(__PACKAGE__) }) {
        next unless $name eq '_new' || $name eq 'apply_roles' || $name =~ /^_has_install/;
        no strict 'refs';
        no warnings 'redefine';
        *{"Shika::$name"} = \&{$name};
    }
}

my $orig_new = \&Shika::_new;
sub _new {
    my $self = $orig_new->(@_);
    while (my ($name, $has) = each %{ $self->meta->{has} }) {
        next unless defined $has->{isa};
        next unless defined $self->{$name};
        Carp::confess "does not pass the type constraint because: Validation failed for '$has->{isa}' failed $_[0]"
            unless Shika::Util::TypeConstraints::check_valid(ref($self), $has, $self, $self->{$name});
    }
    $self;
}

my $orig_apply_roles = \&Shika::apply_roles;
sub apply_roles {
    my ($target, @roles) = @_;

    my @ret = $orig_apply_roles->(@_);

    # check requires
    for my $role (@roles) {
        if (ref $role eq 'HASH') {
            $role  = $role->{role};
        }

        Shika::Util::load_class($role) unless $role->can('meta');
        next unless $role->can('meta');

        LOOP:
        for my $obj (@{ $role->meta->{requires} }) {
            my $require = $obj->[0];
            for my $method (@{ Shika::Util::get_functions($target) }) {
                next LOOP if $require eq $method;
            }
            Carp::croak "requires the method '$require' to be implemented by '$target'";
        }
    }

    @ret;
}

### START HAS_INSTALL

sub _has_install_normal {
    my ($pkg, $n, ) = @_;
    my $has = $pkg->meta->{has}->{$n};
    no strict "refs";
    no warnings 'redefine';
    *{"$pkg\::$n"} = sub {
        if (@_ == 1) { 
            return $_[0]->{$n};
        }

        if (exists $has->{isa}) {
            Carp::confess "does not pass the type constraint because: Validation failed for '$has->{isa}' failed $_[0]"
                unless Shika::Util::TypeConstraints::check_valid($pkg, $has, @_);
        }

        if (@_==2) { 
            return $_[0]->{$n} = $_[1];
        }
        shift->{$n} = \@_;
    };
}
sub _has_install_normal_coerce {
    my ($pkg, $n, ) = @_;
    my $has = $pkg->meta->{has}->{$n};
    no strict "refs";
    no warnings 'redefine';
    *{"$pkg\::$n"} = sub {
        if (@_ == 1) { 
            return $_[0]->{$n};
        }

        if (exists $has->{isa}) {
            Carp::confess "does not pass the type constraint because: Validation failed for '$has->{isa}' failed $_[0]"
                unless Shika::Util::TypeConstraints::check_valid($pkg, $has, @_);
        }

        if (@_==2) { 
            return $_[0]->{$n} = $_[1];
        }
        shift->{$n} = \@_;
    };
}
sub _has_install_lazy {
    my ($pkg, $n, ) = @_;
    my $has = $pkg->meta->{has}->{$n};
    no strict "refs";
    no warnings 'redefine';
    *{"$pkg\::$n"} = sub {
        if (@_ == 1) { 

            unless (exists $_[0]->{$n} && exists $has->{default}) {
                my $code = $has->{default};
                $_[0]->{$n} = ref($code) eq 'CODE' ? $code->($_[0]) : $code;
                if (exists $has->{isa}) {
                    Carp::confess "does not pass the type constraint because: Validation failed for '$has->{isa}' failed $n"
                        unless Shika::Util::TypeConstraints::check_valid($pkg, $has, $_[0], $_[0]->{$n});
                }
                return $_[0]->{$n};
            }
            return $_[0]->{$n};
        }

        if (exists $has->{isa}) {
            Carp::confess "does not pass the type constraint because: Validation failed for '$has->{isa}' failed $_[0]"
                unless Shika::Util::TypeConstraints::check_valid($pkg, $has, @_);
        }

        if (@_==2) { 
            return $_[0]->{$n} = $_[1];
        }
        shift->{$n} = \@_;
    };
}
sub _has_install_lazy_coerce {
    my ($pkg, $n, ) = @_;
    my $has = $pkg->meta->{has}->{$n};
    no strict "refs";
    no warnings 'redefine';
    *{"$pkg\::$n"} = sub {
        if (@_ == 1) { 

            unless (exists $_[0]->{$n} && exists $has->{default}) {
                my $code = $has->{default};
                $_[0]->{$n} = ref($code) eq 'CODE' ? $code->($_[0]) : $code;
                if (exists $has->{isa}) {
                    Carp::confess "does not pass the type constraint because: Validation failed for '$has->{isa}' failed $n"
                        unless Shika::Util::TypeConstraints::check_valid($pkg, $has, $_[0], $_[0]->{$n});
                }
                return $_[0]->{$n};
            }
            return $_[0]->{$n};
        }

        if (exists $has->{isa}) {
            Carp::confess "does not pass the type constraint because: Validation failed for '$has->{isa}' failed $_[0]"
                unless Shika::Util::TypeConstraints::check_valid($pkg, $has, @_);
        }

        if (@_==2) { 
            return $_[0]->{$n} = $_[1];
        }
        shift->{$n} = \@_;
    };
}
sub _has_install_lazy_build {
    my ($pkg, $n, ) = @_;
    my $has = $pkg->meta->{has}->{$n};
    no strict "refs";
    no warnings 'redefine';
    *{"$pkg\::$n"} = sub {
        if (@_ == 1) { 

            unless (exists $_[0]->{$n}) {
                Carp::confess "$pkg does not support builder method '_build_$n' for attribute '$n'"
                    unless my $code = $pkg->can("_build_$n");
                $_[0]->{$n} = $code->($_[0]);
                if (exists $has->{isa}) {
                    Carp::confess "does not pass the type constraint because: Validation failed for '$has->{isa}' failed $n"
                        unless Shika::Util::TypeConstraints::check_valid($pkg, $has, $_[0], $_[0]->{$n});
                }
                return $_[0]->{$n};
            }
            return $_[0]->{$n};
        }

        if (exists $has->{isa}) {
            Carp::confess "does not pass the type constraint because: Validation failed for '$has->{isa}' failed $_[0]"
                unless Shika::Util::TypeConstraints::check_valid($pkg, $has, @_);
        }

        if (@_==2) { 
            return $_[0]->{$n} = $_[1];
        }
        shift->{$n} = \@_;
    };
}
sub _has_install_lazy_build_coerce {
    my ($pkg, $n, ) = @_;
    my $has = $pkg->meta->{has}->{$n};
    no strict "refs";
    no warnings 'redefine';
    *{"$pkg\::$n"} = sub {
        if (@_ == 1) { 

            unless (exists $_[0]->{$n}) {
                Carp::confess "$pkg does not support builder method '_build_$n' for attribute '$n'"
                    unless my $code = $pkg->can("_build_$n");
                $_[0]->{$n} = $code->($_[0]);
                if (exists $has->{isa}) {
                    Carp::confess "does not pass the type constraint because: Validation failed for '$has->{isa}' failed $n"
                        unless Shika::Util::TypeConstraints::check_valid($pkg, $has, $_[0], $_[0]->{$n});
                }
                return $_[0]->{$n};
            }
            return $_[0]->{$n};
        }

        if (exists $has->{isa}) {
            Carp::confess "does not pass the type constraint because: Validation failed for '$has->{isa}' failed $_[0]"
                unless Shika::Util::TypeConstraints::check_valid($pkg, $has, @_);
        }

        if (@_==2) { 
            return $_[0]->{$n} = $_[1];
        }
        shift->{$n} = \@_;
    };
}

### END HAS_INSTALL

1;
