package Toolbox::Moo::Role::DB;
our $VERSION = '0.02';

##~ DIGEST : 44cbc0d55f01f810949f75fdb77b133b
use Moo::Role;

ACCESSORS: {

	has dbh => ( is => 'rw', );
	has _transaction_counter => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return 0 }
	);

	has _statement_limit => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return 1000 }
	);

}

sub _set_dbh {
	my $self = shift;
	use DBI;
	my $dbh = DBI->connect( @_ ) or die $DBI::errstr;
	$self->dbh( $dbh );
	return 1;
}

sub commitmaybe {
	my ( $self ) = @_;
	my $counter = $self->_transaction_counter();
	$counter++;
	if ( $counter >= $self->_statement_limit() ) {
		$self->dbh->commit();
		$counter = 0;
	}
	$self->_transaction_counter( $counter );

}

sub commithard {
	my ( $self ) = @_;
	$self->_transaction_counter( 0 );
	$self->dbh->commit();
}

1;
