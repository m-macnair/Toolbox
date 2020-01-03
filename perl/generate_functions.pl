#!/usr/bin/perl
use strict;
use warnings;
use Ryza::CombinedCLI;
use Data::Dumper;
main();

sub main {

    my $c = Ryza::CombinedCLI::array_config(
        [
            [

                qw/ functions prefixes suffixes /
            ]
        ],
        [
            qw/ headlevel noreturn explicitreturn doprefixfirst returnprivate objectoriented /
        ]
    );
    my $header = '=head1 Generated Functions' . $/;

    $c->{headlevel} ||= 3;
    my ( $output, $footer );
    if ( $c->{functions} ) {
        for ( split( ' ', $c->{functions} ) ) {
            $header .= "\t$_$/";
            $output .= generate_sub( $_, $c );
            $footer .= generate_private_sub( $_, $c )
              if $c->{returnprivate} && $c->{objectoriented};
        }
    }
    else {
        die("Must provide both prefixes and suffixes")
          unless ( $c->{prefixes} and $c->{suffixes} );
        my @prefixes = sort( split( ' ', $c->{prefixes} ) );
        my @suffixes = sort( split( ' ', $c->{suffixes} ) );

        if ( $c->{doprefixfirst} ) {
            for my $prefix (@prefixes) {
                for my $suffix (@suffixes) {
                    $header .= "\t$prefix\_$suffix$/";
                    $output .= generate_sub( "$prefix\_$suffix", $c );
                    $footer .= generate_private_sub( "$prefix\_$suffix", $c )
                      if $c->{returnprivate} && $c->{objectoriented};
                }
            }
        }
        else {

            for my $suffix (@suffixes) {
                for my $prefix (@prefixes) {
                    $header .= "\t$prefix\_$suffix$/";
                    $output .= generate_sub( "$prefix\_$suffix", $c );
                    $footer .= generate_private_sub( "$prefix\_$suffix", $c )
                      if $c->{returnprivate} && $c->{objectoriented};
                }
            }
        }

    }
    $header .= "=cut$/";
    print $header;
    print $output;
    print $footer;
}

sub generate_sub {
    my ( $name, $c ) = @_;

    my $return = "=head$c->{headlevel} $name$/\t$/=cut$/sub $name {$/";
    if ( $c->{objectoriented} ) {
        $return .= "\t" . 'my ($self,$p) = @_;' . $/;
    }
    if ( $c->{explicitreturn} ) {
        $return .= "\t" . "$c->{explicitreturn}$/";
    }
    elsif ( $c->{returnprivate} ) {
        $return .= "\t" . 'return $self->_' . $name . '($p);' . $/;
    }
    else {
        $return .= "\t" . "return { pass => 1 }$/" unless $c->{noreturn};
    }
    $return .= "}$/$/";

    return $return;    #return!

}

sub generate_private_sub {
    my ( $name, $c ) = @_;
    my $return = "=head$c->{headlevel} _$name$/\t$/=cut$/sub _$name {$/";

    $return .= "\t" . 'my ($self,$p) = @_;' . $/;
    $return .= "\t" . q#die('not implemented');# . $/;
    $return .= "}$/$/";

    return $return;    #return!
}

