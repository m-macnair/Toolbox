package Toolbox::ExcelWriterSugar::Worksheet;

#ABSTRACT:Excel::Writer::XLSX worksheets with cursors awareness
use Moo;
use Carp qw/confess/;
ACCESSORS: {
	has ewx         => ( is => 'rw', );
	has cws         => ( is => 'rw', );
	has current_col => ( is => 'rw', );
	has current_row => ( is => 'rw', );

}

sub BUILD {
	my ( $self, $args ) = @_;

	confess( "Missing the parent Excel::Writer::XLSX object" ) unless ( ref( $args->{ewx} ) eq 'Excel::Writer::XLSX' );
	$self->ewx( $args->{ewx} );
	$self->cws( $args->{cws}                 || $self->ewx()->add_worksheet() );
	$self->current_col( $args->{current_col} || 0 );
	$self->current_row( $args->{current_row} || 0 );

}

sub write {
	my $self = shift;
	$self->cws->write( @_ );
}

=head3 next_col
set the current_col to the next in the horizontal step, and return what that is 
=cut

sub next_col {
	my ( $self ) = @_;
	my $current  = $self->current_col();
	my $new      = $current + 1;

	# 	for my $this (uc($current) .. 'Z'){
	# 		next if($this eq $current);
	# 		$current = $this;
	# 		# TODO handle ZZ
	# 		last;
	# 	}
	$self->current_col( $new );
	return $new;

}

sub next_row {
	my ( $self ) = @_;
	my $current  = $self->current_row();
	my $new      = $current + 1;

	$self->current_row( $new );
	return $new;

}

sub next_line {
	my ( $self ) = @_;
	$self->next_row();
	$self->current_col( 0 );

}

sub write_rows {
	my ( $self, $stack, $worksheet ) = @_;
	$worksheet ||= $self->cws();
	for my $line ( @{$stack} ) {
		$self->write_line( $line );
	}
}

sub write_line {
	my ( $self, $line, $worksheet ) = @_;
	$worksheet ||= $self->cws();
	for my $cell ( @{$line} ) {
		$worksheet->write( $self->current_row, $self->current_col, $cell );
		$self->next_col();
	}
	$self->next_line();
}

sub number_to_letter {
	my ( $self, $num ) = @_;

	my $return;

	# 	my $big = $num % 25;
	# 	if($big) {
	# handle AA etc
	# 	}
	$return = $self->_short_number_to_letter( $num );
	return $return; # return !

}

sub _short_number_to_letter {
	my ( $self, $num ) = @_;
	my @letters = qw/ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/;
	return $letters[$num];
}

1;
