package Toolbox::ExcelWriterSugar;

#ABSTRACT: useExcel::Writer::XLSX quickly
use Moo;
use Toolbox::ExcelWriterSugar::Worksheet;

require Excel::Writer::XLSX;
ACCESSORS: {
	has ewx           => ( is => 'rw', );
	has ofn           => ( is => 'rw', );
	has worksheet_map => ( is => 'rw', default => sub { return {} } );
}

sub BUILD {
	my ( $self, $args ) = @_;
	if ( $args->{ewx} ) {
		$self->ewx( $args->{ewx} );
	} else {
		confess( "Missing output file name and no existing object provided" ) unless $args->{ofn};
		$self->ofn( $args->{ofn} );
		my $ewx = Excel::Writer::XLSX->new( $self->ofn() );

		#this doesn't appear to work :(
		$ewx->set_calc_mode( 'auto' );
		$self->ewx( $ewx );
	}
}

sub worksheet {
	my ( $self, $name, $existing ) = @_;
	$name ||= 'default';
	my $return;
	unless ( $return = $self->worksheet_map->{$name} ) {
		$return = Toolbox::ExcelWriterSugar::Worksheet->new(
			{
				ewx => $self->ewx(),
				cws => $existing,
			}
		);
		$self->worksheet_map->{$name} = $return;
	}
	return $return; #return!

}

sub DEMOLISH {
	my ( $self, $in_global_destruction ) = @_;
	$self->ewx->close();
}

1;

