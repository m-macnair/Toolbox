package Toolbox::Moo::Role::DB;
our $VERSION = 'v1.0.1';

##~ DIGEST : 057c6e57601b94ec6e8bd86eb84d2d55
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

=head3 _func_sth_accessor
 THIS DOESN'T AND CAN'T WORK 
=cut

# sub _mk_sth_accessor {
# 	my ($self, $pair ) = @_;
# 	has $pair->[0] => (
# 		is      => 'rw',
# 		lazy    => 1,
# 		default => sub { $_[0]->dbh->prepare( $pair->[1] ) }
# 	);
# }
1;
