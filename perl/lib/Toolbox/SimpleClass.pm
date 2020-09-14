use strict;

package Toolbox::SimpleClass;

sub new {
    my ( $class, $conf ) = @_;
    my $self = {};
    bless $self, $class;
    my $initresult = $self->init($conf);
    die $initresult->{fail} unless $initresult->{pass};
    return $self;
}

sub init {
    my ( $self, $conf ) = @_;
    return { pass => 1 };
}

sub configure {
    my ( $self, $conf, $keys ) = @_;
    $keys = [] unless $keys;
    for ( @{$keys} ) {
        if ( exists( $conf->{$_} ) ) {
            $self->{$_} = $conf->{$_};
        }
    }
}

sub required {
    my ( $self, $keys ) = @_;
    $keys = [] unless $keys;
    for ( @{$keys} ) {
        unless ( $self->{$_} ) {
            return { fail => "Missing key [$_]" };
        }
    }
}

sub defaults {
    my ( $self, $defaults ) = @_;
    $defaults = {} unless $defaults;
    for my $key ( sort( keys( %{$defaults} ) ) ) {
        unless ( exists( $self->{$key} ) ) {
            $self->{$key} = $defaults->{$key};
        }
    }
}

1;
