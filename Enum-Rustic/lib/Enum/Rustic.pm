package Enum::Rustic;

use strict;
use warnings;
use Carp 'croak';
use overload '""' => \&_stringify, fallback => 1;

our $VERSION = '0.01';

sub import {
    my $class = shift;
    my ($target_package) = caller(0);

    my $ctx = {
        _enum   => {},
        _params => {},
    };

    my $serial = 0;

    foreach my $arg (@_) {
        my ($name, $params) = ($arg, []);
        $name =~ s/\s//g;

        if ($name =~ /^([^()]+)\(([^)]+)\)/) {
            $name = $1;
            $params = [ split /,/, $2 ];
        }

        $ctx->{_enum}->{$name} = $serial;
        $ctx->{_params}->{$name} = $params;

        no strict 'refs';
        *{ $target_package . '::' . $name } = _make_constructor($name, $params, $ctx);

        $serial++;
    }

    _install_helpers($target_package, $ctx);
}

sub _make_constructor {
    my ($name, $params, $ctx) = @_;

    return sub {
        my @args = @_;

        # todo: понять, как действовать, если ожидаем @ параметр, а нам дали, вместо ссылки [arg1,arg2,...] список (arg1,arg2,...). 
        if (@$params && $params->[0] eq '@' && @args > 1) {
            @args = [ @args ];
        }

        for my $idx (0 .. $#{$params}) {
            my $m = $params->[$idx];
            my $val = $args[$idx] // do {
                croak "Undefined parameter at position $idx for variant '$name'";
            };

            my $ref = ref($val);

            if ($m eq '$' && $ref ne '') {
                croak "Parameter $idx for '$name' must be scalar, got reference ($ref)";
            }
            elsif ($m eq '@' && $ref ne 'ARRAY') {
                croak "Parameter $idx for '$name' must be array reference, got '$ref'";
            }
            elsif ($m eq '%' && $ref ne 'HASH') {
                croak "Parameter $idx for '$name' must be hash reference, got '$ref'";
            }
        }

        my $self = {
            %$ctx,
            name => $name,
            data => \@args,
        };

        bless $self, (caller(1))[0]; # bless в пакет, который использовал use
    };
}

sub _install_helpers {
    my ($package, $ctx) = @_;

    no strict 'refs';

    *{ $package . '::name' } = sub { shift->{name} };
    *{ $package . '::value' } = sub { my $self = shift; $self->{_enum}->{ $self->{name} } };
    *{ $package . '::data' } = sub { shift->{data} };

    *{ $package . '::match' } = sub {
        my ($self, %handlers) = @_;
        my $variant = $self->{name};

        if (exists $handlers{$variant}) {
            return $handlers{$variant}->(@{ $self->{data} });
        }
        elsif (exists $handlers{'_'}) {
            return $handlers{'_'}->();
        }
        croak "No handler for variant '$variant' and no default handler '_' provided";
    };

    *{ $package . '::is' } = sub {
        my ($self, $variant) = @_;
        return $self->{name} eq $variant;
    };
}

sub _stringify {
    my $self = shift;
    my $data_str = join ", ", map {
        ref($_) ? sprintf('%s(...)', ref($_)) : $_
    } @{ $self->{data} };
    return $self->{name} . "(" . $data_str . ")";
}

1;

__END__

=head1 NAME

Enum::Rustic - Rust-style enums (algebraic data types) for Perl

=head1 SYNOPSIS

    package Shape;
    use Enum::Rustic qw(
        Circle(radius)
        Rectangle(width, height)
        Pointless()
    );

    package main;

    my $c = Shape::Circle(5.0);
    my $r = Shape::Rectangle(10, 20);  # auto-packed to [10,20]

    print $c->match(
        Circle    => sub { my ($r) = @_; 3.14 * $r**2 },
        Rectangle => sub { my ($w, $h) = @_; $w * $h },
        _         => sub { 0 }
    ); # prints 78.5

    if ($c->is('Circle')) {
        print "It's a circle with radius ", $c->data->[0], "\n";
    }

    print $c; # Circle(5)

=head1 DESCRIPTION

C<Enum::Rustic> brings Rust-style enums with data-carrying variants and pattern matching to Perl.

Define variants with optional typed parameters:

  VariantName          # no data
  VariantName($)       # scalar
  VariantName(@)       # list (auto-packed)
  VariantName(%)       # hashref

=head1 METHODS

=head2 name()

Returns variant name as string.

=head2 value()

Returns variant ordinal number (for FFI compatibility).

=head2 data()

Returns arrayref of variant data.

=head2 is($variant_name)

Returns true if variant matches.

=head2 match(%handlers)

Performs pattern matching. Keys are variant names, values are coderefs.

Use C<'_'> for default case.

=head1 STRING OVERLOAD

Objects stringify to C<VariantName(arg1, arg2, ...)> for easy debugging.

=head1 AUTHOR

Your Name <your.email@example.com>

=head1 LICENSE

Same as Perl itself.

=cut
