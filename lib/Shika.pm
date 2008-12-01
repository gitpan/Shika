package Shika;

use strict;
use warnings;
use Carp ();
our $VERSION = '0.01_01';
if ($] < 5.009_005) {
    require MRO::Compat;
}
use Shika::Util;
require Shika::Util::TypeConstraints;

if ($ENV{SHIKA_DEVEL}) {
    require Shika::Devel;
    Shika::Devel->import;
    *DEVEL_MODE = sub (){ 1 };
} else {
    *DEVEL_MODE = sub (){ 0 };
}

if ($ENV{SHIKA_DEBUG}) {
    *DEBUG_MODE = sub (){ 1 };
} else {
    *DEBUG_MODE = sub (){ 0 };
}

our $PurePerl = 1;
#   $PurePerl = $ENV{SHIKA_PUREPERL} if $ENV{SHIKA_PUREPERL};

#   if (! $PurePerl) {
#       local $@;
#       local $^W = 0;
#       require XSLoader;
#       $PurePerl = !eval{ XSLoader::load(__PACKAGE__, $VERSION); 1 };
#       warn "Failed to load XS mode: $@" if $@ && Shika::DEBUG_MODE();
#   }


sub import {
    my $pkg = caller(0);
    strict->import;
    warnings->import;

    Shika::init_class($pkg);
}

sub init_class {
    my $pkg = shift;
    my $meta = +{
        has      => {},
        modifier => {},
        role     => [],
    };

    no strict 'refs';
    *{"$pkg\::new"}     = \&_new;
    *{"$pkg\::has"}     = \&_has;
    *{"$pkg\::extends"} = \&_extends;
    *{"$pkg\::with"}    = \&_with;
    *{"$pkg\::before"}  = \&_before;
    *{"$pkg\::after"}   = \&_after;
    *{"$pkg\::around"}  = \&_around;
    *{"$pkg\::meta"}    = sub { $meta };
}

sub _new {
    my $class = shift;
    my $args = do {
        if ( scalar @_ == 1 ) {
            if ( defined $_[0] ) {
                ( ref( $_[0] ) eq 'HASH' ) or Carp::croak("Single parameters to new() must be a HASH ref: $_[0]");
                +{ %{ $_[0] } };
            }
            else {
                Carp::croak("why do you pass the undef for $class?");
            }
        }
        else {
            +{@_};
        }
    };

    for my $klass ($class, @{mro::get_linear_isa($class)}) {
        next unless $klass->can('meta');
        my %has_map = %{ $klass->meta->{has} };
        while (my ($name, $has) = each %has_map) {
            # set default values
            if (
                (! $args->{$name}    ) &&
                (  $has->{default}   ) &&
                (! $has->{lazy}      ) &&
                (! $has->{lazy_build})
            ) {
                my $code = $has->{default};
                $args->{$name} = ref($code) eq 'CODE' ? $code->() : $code;
            }

            # process coerce
            if ( $args->{$name} && $has->{coerce} ) {
                Carp::confess "does not pass the type constraint because: Validation failed for '$has->{isa}' failed $name"
                    unless Shika::Util::TypeConstraints::check_valid($class, $has, undef, $args->{$name});
            }

            # process 'required'
            if (!$args->{$name} && $has->{required}) {
                Carp::croak "missing parameter $name for $class";
            }
        }
    }

    my $self = bless $args, $class;
    if ($self->can('BUILD')) {
        $self->BUILD($args);
    }
    $self;
}

sub _has {
    my $pkg = caller(0);
    Shika::add_attribute($pkg, shift, +{ @_ });
}

sub add_attribute {
    my ($target, $name, $attr) = @_;

    Carp::croak "You cannot have coercion without specifying a type constraint on attribute ($name)"
        if $attr->{coerce} && !$attr->{isa};

    if ($name =~ s/^\+//) {
        my $orig = $target->meta->{has}->{$name} or Carp::confess "Cannot overwrite $name.$target doesn't have a $name";
        $attr = +{ %$orig, %$attr };
    }

    no strict 'refs';

    $target->meta->{has}->{$name} = $attr;

    if (my $handles = $attr->{handles}) {
        $handles = [$handles] unless ref $handles;
        if (ref $handles eq 'ARRAY') {
            for my $handle (@$handles) {
                *{"$target\::$handle"} = sub {
                    shift->$name->$handle(@_)
                };
            }
        } elsif (ref $handles eq 'HASH') {
            while (my ($key, $val) = each %$handles) {
                *{"${target}::${key}"} = sub {
                    shift->$name->$val(@_)
                };
            }
        } else {
            Carp::croak "Shika can handles ARRAYREF or HASHREF";
        }
    }

    {
        my $f1 =       $attr->{lazy} ? 'lazy'
                                    :
                $attr->{lazy_build} ? 'lazy_build'
                                    : 'normal';
        my $f2 = $attr->{coerce} ? '_coerce' : '';
        my $meth = "_has_install_${f1}${f2}";
        &{"Shika\::$meth"}( $target, $name );
    }
}

### START HAS_INSTALL

sub _has_install_normal {
    my ($pkg, $n, ) = @_;
    no strict "refs";
    no warnings 'redefine';
    *{"$pkg\::$n"} = sub {
        if (@_ == 1) { 
            return $_[0]->{$n};
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
            }
            return $_[0]->{$n};
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
            }
            return $_[0]->{$n};
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

sub _extends {
    my $pkg = caller(0);
    my @parents = @_;
    no strict 'refs';
    unshift @{"$pkg\::ISA"}, @parents;
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

        for my $has (@{ $role->meta->{has} }) {
            Shika::add_attribute($target, $has->{name}, $has->{attr});
        }

        # install method modifiers
        while (my($name, $modifiers) = each %{ $role->meta->{modifier} }) {
            Carp::confess "The method '$name' is not found in the inheritance hierarchy for class $target"
                unless $target->can($name);
            my $target_modifier = _init_modifier($target, $name);
            for my $type (qw/ before after around /) {
                push @{ $target_modifier->{$type} }, @{ $modifiers->{$type} };
            }
            _install_modifier($target, $name);
        }

        # copy subtype/coerce
        require Shika::Util::TypeConstraints;
        Shika::Util::TypeConstraints::copy_types($role, $target, '-all');

        push @{ $target->meta->{role} }, $role;
    }
}

sub _with {
    my $pkg = caller(0);
    my @roles = @_;
    Shika::apply_roles($pkg, @roles);
}

my $compile_around_method = sub {{
    my $f1 = pop;
    return $f1 unless @_;
    my $f2 = pop;
    push @_, sub { $f2->( $f1, @_ ) };
    redo;
}};

sub _install_modifier {
    my($pkg, $name) = @_;
    my $modifier = _init_modifier($pkg, $name);
    my $before = $modifier->{before};
    my $after  = $modifier->{after};
    my $around = $modifier->{around};

    if (@$around) {
        $modifier->{around_cache} = $compile_around_method->(
            @$around,
            $modifier->{orig}
        );
    }

    if (@$before && @$after) {
        $modifier->{cache} = sub {
            $_->(@_) for reverse @{$before};
            my @rval;
            ((defined wantarray) ?
                ((wantarray) ?
                    (@rval = $modifier->{around_cache}->(@_))
                    :  
                    ($rval[0] = $modifier->{around_cache}->(@_)))
                :  
                $modifier->{around_cache}->(@_));
            $_->(@_) for @{$after};
            return unless defined wantarray;
            return wantarray ? @rval : $rval[0];
        }
    } elsif (@$before && !@$after) {
        $modifier->{cache} = sub {
            $_->(@_) for reverse @{$before};
            return $modifier->{around_cache}->(@_);
        }
    } elsif (@$after && !@$before) {
        $modifier->{cache} = sub {
            my @rval;
            ((defined wantarray) ?
                ((wantarray) ?
                    (@rval = $modifier->{around_cache}->(@_))
                    :  
                    ($rval[0] = $modifier->{around_cache}->(@_)))
                :  
                $modifier->{around_cache}->(@_));
            $_->(@_) for @{$after};
            return unless defined wantarray;
            return wantarray ? @rval : $rval[0];
        }
    } else {
        $modifier->{cache} = $modifier->{around_cache};
    }

    no strict 'refs';
    no warnings 'redefine';
    *{"$pkg\::$name"} = sub { goto $modifier->{cache} };
}

sub _init_modifier {
    my($pkg, $name) = @_;
    Carp::confess "The method '$name' is not found in the inheritance hierarchy for class $pkg"
        unless $pkg->can($name);
    my $code = $pkg->can($name);
    $pkg->meta->{modifier}->{$name} ||= +{
        around_cache => $code,
        cache        => $code,
        orig         => $code,
        around       => [],
        before       => [],
        after        => [],
    };
}

{
    no strict 'refs';
    for my $_type (qw/before after around/) {
        my $type = $_type;
        *{"add_${type}_method_modifier"} = sub {
            my ($pkg, $stuff, $code) = @_;
            if (!ref $stuff) {
                $stuff = [$stuff];
            }
            for my $name (@$stuff) {
                my $modifier = _init_modifier($pkg, $name);
                push @{ $modifier->{$type} }, $code;
                _install_modifier($pkg, $name);
            }
        };
        *{"_${type}"} = sub {
            my $pkg = caller(0);
            my $name = shift;
            my $code = shift;
            *{"add_${type}_method_modifier"}->($pkg, $name, $code);
        }
    }
}

1;
__END__

=head1 NAME

Shika - Lightweight class builder with DSL

=head1 SYNOPSIS

  package Point;
  use Shika; # automatically turns on strict and warnings

  has 'x';
  has 'y';

  sub clear {
      my $self = shift;
      $self->x(0);
      $self->y(0);
  }

  package Point3D;
  use Shika;

  extends 'Point';

  has 'z';

  after 'clear' => sub {
      my $self = shift;
      $self->z(0);
  };

=head1 DESCRIPTION

Shika is yet another class builder.

B<THIS MODULE IS IN ITS BETA QUALITY. THE API IS STOLEN FROM SCRAPI BUT MAY CHANGE IN THE FUTURE>

=head1 EXPORTED FUNCTIONS

=over 4

=item has

=item extends(@superclasses)

This function will set the superclass(es) for the current class.

=item with(@roles)

This will apply a given set of @roles to the local class.

=item before $name => sub { }

=item after $name => sub { }

=item around $name => sub { }

method modifiers.

=back

=head1 INTROSPECTION FUNCTIONS

=over 4

=item Shika::init_class($klass)

install Shika methods in your class

=item Shika::add_attribute($klass, $name, $attr)

add attribute named $name to $klass.

=item Shika::apply_roles($target, @roles)

apply roles to $target.

=back

=head1 WHY YET ANOTHER ONE?

I want just size class builder.

=head1 AUTHOR

tokuhirom

yappo

lestrrat

typester

charsbar

miyagawa

kan

walf443

kazuho

hidek

mattn

gfx

=head1 SEE ALSO

L<Moose>, L<Mouse>

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/Shika/trunk Shika

Shika is Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
