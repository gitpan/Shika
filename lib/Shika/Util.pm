package Shika::Util;
use strict;
use warnings;

# copied from Class::Inspector
sub get_functions {
    my $name = shift;

    no strict 'refs';
    # Get all the CODE symbol table entries
    my @functions = grep { /\A[^\W\d]\w*\z/o }
        grep { defined &{"${name}::$_"} }
            keys %{"${name}::"};
    \@functions;
}

sub copy_functions {
    my ($src, $dst, $alias) = @_;
    $src = ref $src if ref $src;
    $dst = ref $dst if ref $dst;

    print "[debug] copy functions $src to $dst\n" if Shika::DEBUG_MODE();
    no strict 'refs';
    for my $method (@{ Shika::Util::get_functions($src) }) {
        next if $method eq 'has' || $method eq 'requires' || $method eq 'meta' || $method eq 'with';
        my $dstmethod = $alias->{$method} ? $alias->{$method} : $method;
        print "[debug]   copying method $method\n" if Shika::DEBUG_MODE();
        if ($dst->can($dstmethod)) {
            print "[debug]   $dst already have $dstmethod. skip\n" if Shika::DEBUG_MODE();
            next;
        }
        *{"${dst}::${dstmethod}"} = *{"${src}::${method}"};
    }
}

sub load_class {
    my $klass = shift;
    eval "require $klass"; ## no critic ### too bad
    print "[debug] cannot load class $@" if Shika::DEBUG_MODE() && $@;
}

1;
