use strict;

package Toolbox::Ja;
use base "Data::Validate::Japanese";

sub contains_any {
	my ( $self, $string, $conf ) = @_;

	for my $offset ( 0 ... ( length( $string ) - 1 ) ) {

		# 		warn $offset;
		my $char = substr( $string, $offset, 1 );

		# 		warn $char;
		for ( keys( %{$conf} ) ) {
			my $action = "is_$_";

			# 			warn "is_$_($char)";
			return 1 if $self->$action( $char );
		}
	}
}

sub is_ascii {
	my ( $self, $string ) = @_;
	$string =~ m/[A-Z a-z]/;
}

1;
