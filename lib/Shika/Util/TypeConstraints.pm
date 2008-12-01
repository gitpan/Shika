package Shika::Util::TypeConstraints;
use strict;
use warnings;

{
    my $SUBTYPE = +{};
    my $COERCE = +{};

    sub import {
        my $class  = shift;
        my %args   = @_;
        my $caller = caller(0);

        $SUBTYPE->{$caller} ||= +{};
        $COERCE->{$caller}  ||= +{};

        if (defined $args{'-export'} && ref($args{'-export'}) eq 'ARRAY') {
            no strict 'refs';
            *{"$caller\::import"} = sub { _import(@_) };
        }

        no strict 'refs';
        *{"$caller\::subtype"}     = \&_subtype;
        *{"$caller\::coerce"}      = \&_coerce;
        *{"$caller\::class_type"}  = \&_class_type;
        *{"$caller\::role_type"}   = \&_role_type;
    }

    sub _import {
        my($class, @types) = @_;
        return unless exists $SUBTYPE->{$class} && exists $COERCE->{$class};
        my $pkg = caller(1);
        return unless @types;
        copy_types($class, $pkg, @types);
    }

    sub copy_types {
        my($src, $target, @types) = @_;
        $SUBTYPE->{$target} ||= +{};
        $COERCE->{$target}  ||= +{};

        if ($types[0] eq '-all') {
            @types = ();
            my %cache;
            for my $type (%{ $SUBTYPE->{$src} }, %{ $COERCE->{$src} }) {
                next if $cache{$type}++;
                push @types, $type;
            }
        }

        for my $type (@types) {
            if ($SUBTYPE->{$src}->{$type}) {
                $SUBTYPE->{$target}->{$type} = $SUBTYPE->{$src}->{$type};
            }
            if ($COERCE->{$src}->{$type}) {
                $COERCE->{$target}->{$type} = $COERCE->{$src}->{$type};
            }
        }
    }

    sub _subtype {
        my $pkg = caller(0);
        my($name, $stuff) = @_;
        if (ref $stuff eq 'HASH') {
            my $as = $stuff->{as};
            $stuff = \&{"Shika::Util::TypeConstraints::_check_$as"}
        }
        $SUBTYPE->{$pkg}->{$name} = $stuff;
    }

    sub _coerce {
        my $pkg = caller(0);
        my($name, $conf) = @_;
        $COERCE->{$pkg}->{$name} = $conf;
    }

    sub _class_type {
        my $pkg = caller(0);
        $SUBTYPE->{$pkg} ||= +{};
        my($name, $conf) = @_;
        my $class = $conf->{class};
        $SUBTYPE->{$pkg}->{$name} = sub {
            defined $_[0] && ref($_[0]) eq $class;
        };
    }

    sub _role_type {
        my $pkg = caller(0);
        $SUBTYPE->{$pkg} ||= +{};
        my($name, $conf) = @_;
        my $role = $conf->{role};
        $SUBTYPE->{$pkg}->{$name} = sub {
            return unless defined $_[0] && ref($_[0]) && eval { $_[0]->can('meta') };
            for my $target_role (@{ $_[0]->meta->{role} }) {
                return 1 if $role eq $target_role;
            }
            return 0;
        };
    }

    sub _apply_coerce {
        my $pkg = shift;
        my $isa = shift;

        my @types = ( $isa );
        if ($isa =~ /\|/) { # or
            $isa =~ s/\s//g;
            for my $type (split /\|/, $isa) {
                push @types, $type;
            }
        }

        my %type_cache;
        for my $type (@types) {
            next unless defined $COERCE->{$pkg} && defined $COERCE->{$pkg}->{$type};
            my $detect_type = $type_cache{$type} ||= do {
                my $t;
                for my $coerce_type (keys %{ $COERCE->{$pkg}->{$type} }) {
                    if (_check($pkg, $coerce_type, @_)) {
                        $t = $coerce_type;
                        last;
                    }
                }
                $t;
            };
            next unless $detect_type;
            $COERCE->{$pkg}->{$type}->{$detect_type}->(@_);
            return _check($pkg, $isa, @_);
        }
    }

    sub _check {
        my $pkg = shift;
        my $isa = shift;
        if (my $code = __PACKAGE__->can("_check_$isa")) {
            return $code->(@_);
        }
        if ($isa =~ /\|/) { # or
            $isa =~ s/\s//g;
            for my $type (split /\|/, $isa) {
                return 1 if _check($pkg, $type, @_);
            }
            return;
        }
        if (exists $SUBTYPE->{$pkg} && exists $SUBTYPE->{$pkg}->{$isa}) {
            return $SUBTYPE->{$pkg}->{$isa}->(@_);
        }
        defined $_[0] && ref($_[0]) && eval { $_[0]->isa($isa) };
    }
}

sub check_valid {
    my $pkg = shift;
    my $has = shift;
    my $obj = shift;
    my $isa = $has->{isa};
    return 1 unless @_;
    return 1 unless $isa;
    return 1 if @_ > 1 && $isa eq 'ARRAY';
   _check($pkg, $isa, @_) ? 1 : $has->{coerce} ? _apply_coerce($pkg, $isa, @_) : 0;
}

sub _check_Any {
    1;
}

sub _check_Bool {
    $_[0] =~ /^[01]$/;
}

sub _check_Maybe {
    1;
}

sub _check_Undef {
    !defined($_[0]);
}

sub _check_Defined {
    defined $_[0];
}

sub _check_Value {
    defined $_[0] && !ref($_[0]);
}

sub _check_Num {
    defined $_[0] && $_[0] =~ /^\-?[0-9]+(?:\.[0-9])$/;
}

sub _check_Int {
    defined $_[0] && $_[0] =~ /^\-?[0-9]+$/;
}

sub _check_Str {
    defined $_[0] && !ref($_[0]);
}

sub _check_ClassName {
    die 'not implement';
}

sub _check_Ref {
    ref($_[0]);
}

sub _check_ScalarRef {
    ref($_[0]) eq 'SCALAR';
}

sub _check_ArrayRef {
    ref($_[0]) eq 'ARRAY';
}

sub _check_HashRef {
    ref($_[0]) eq 'HASH';
}

sub _check_CodeRef {
    ref($_[0]) eq 'CODE';
}

sub _check_GlobRef {
    ref($_[0]) eq 'GLOB';
}

sub _check_FileHandle {
    die 'not implement';
}

sub _check_Object {
    die 'not implement';
}

sub _check_Role {
    die 'not implement';
}

1;
__END__

=head1 NAME

Shika::Util::TypeConstraints - type constraint utilities for Shika

=head1 SYNOPSIS

    package Foo;
    use Shika;
    use Shika::Util::TypeConstraints;

    subtype Handler => { as => 'CodeRef' };
    coerce Handler => {
         Str => sub { $_[0] = \&{$_[0]} }
    };

=head1 DESCRIPTION

type constraint utilities for Shika.

=cut

