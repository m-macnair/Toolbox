package Toolbox::ExcelWriterSugar;

#ABSTRACT: useExcel::Writer::XLSX quickly
use Moo;
use Toolbox::ExcelWriterSugar::Worksheet;

require Excel::Writer::XLSX;
ACCESSORS: {
    has ewx => ( is => 'rw', );
    has ofn => ( is => 'rw', );

}

sub BUILD {
    my ( $self, $args ) = @_;
    if ( $args->{ewx} ) {
        $self->ewx( $args->{ewx} );
    }
    else {
        confess("Missing output file name and no existing object provided")
          unless $args->{ofn};
        $self->ofn( $args->{ofn} );
        my $ewx = Excel::Writer::XLSX->new( $self->ofn() );

        #this doesn't appear to work :(
        $ewx->set_calc_mode('auto');
        $self->ewx($ewx);
    }
}

# TODO find a way to store objects persitently without breaking the output
sub worksheet {
    my ( $self, $name, $existing ) = @_;

    my $return = Toolbox::ExcelWriterSugar::Worksheet->new(
        {
            ews => $self,
            cws => $existing,
        }
    );

    return $return;    #return!

}

sub DEMOLISH {
    my ( $self, $in_global_destruction ) = @_;
    if ( my $ewx = $self->ewx ) {
        $ewx->close();
    }

}

1;

