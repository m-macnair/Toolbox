package Toolbox::ExcelWriterSugar::Worksheet;

#ABSTRACT:Excel::Writer::XLSX worksheets with cursors awareness
use Moo;
use Carp qw/confess/;
use POSIX qw/floor /;
ACCESSORS: {
	has ews         => ( is => 'rw', );
	has wso         => ( is => 'rw', );
	has current_col => ( is => 'rw', );
	has current_row => ( is => 'rw', );

}

sub BUILD {
	my ( $self, $args ) = @_;
	$self->_init( $args );

}

sub _init {
	my ( $self, $args ) = @_;
	confess( "Missing the parent Toolbox::ExcelWriterSugar object" )
	  unless ( ref( $args->{ews} ) eq 'Toolbox::ExcelWriterSugar' );
	$self->ews( $args->{ews} );
	my $current_work_sheet =
	  $args->{wso} || $self->ews()->ewx()->add_worksheet();
	$self->wso( $current_work_sheet );

	$self->current_col( $args->{current_col} || 0 );
	$self->current_row( $args->{current_row} || 0 );

}

#for reasons beyond understanding, this goes Row, Column (y,x) instead of Column,Row (x,y)
sub write {
	my $self = shift;

	$self->wso->write( @_ );
}

=head3 fwrite
	Keep writing on the same row until further notice 
=cut

sub fwrite {
	my $self = shift;
	my $row  = $self->current_row;
	my $col  = $self->next_col();

	$self->write( $row, $col, @_ );

	# 	$self->write(
	# 		$self->current_row(),
	# 		$self->next_col(),
	# 		@_
	# 	);
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

sub nr {
	next_row( @_ );
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
	my ( $self, $stack ) = @_;

	for my $line ( @{$stack} ) {
		$self->write_line( $line );
	}
}

sub write_line {
	my ( $self, $line ) = @_;

	for my $cell ( @{$line} ) {
		$self->write( $self->current_row, $self->current_col, $cell );
		$self->next_col();
	}
	$self->next_line();
}

sub coord_to_cell {
	my ( $self, $x, $y ) = @_;
	my $x_cell = $self->number_to_letter( $x );
	my $y_cell = $y + 1;
	if ( wantarray() ) {
		return ( $x_cell, $y_cell );
	} else {
		return "$x_cell$y_cell";
	}
}

# TODO handle BB case which is wrong
sub number_to_letter {
	my ( $self, $num ) = @_;

	my $return;

	my $big = floor( $num / 25 );
	if ( $big ) {
		my $small = $num % 25;
		$return .= $self->_short_number_to_letter( $big - 1 );
		$small -= 1;
		$small = 0 if $small < 0;
		$return .= $self->_short_number_to_letter( $small );
	} else {
		$return .= $self->_short_number_to_letter( $num );
	}
	return $return; # return !

}

sub _short_number_to_letter {
	my ( $self, $num ) = @_;

	my @letters = qw/ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/;
	return $letters[$num];
}

1;
