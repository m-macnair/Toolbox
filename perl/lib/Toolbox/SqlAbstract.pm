package Toolbox::SqlAbstract;
our $VERSION = 'v1.0.3';

##~ DIGEST : 0da7a7af667e82cef5b3ab706d3ce13a

#ABSTRACT: use DBI and SqlAbstract quickly - mainly to reinforce my knowledge of moo
use Try::Tiny;
use Moo;
ACCESSORS: {

	# subclasses can do funky things with this - so long as it provides a DBI $dbh
	has dbh => (
		is       => 'rw',
		required => 1,
	);
	has sqla => (
		is      => 'rw',
		lazy    => 1,
		builder => '_build_abstract'
	);
}

sub select {
	my $self = shift;
	my ( $s, @p ) = $self->sqla->select( @_ );
	return $self->_shared_query( $s, \@p );
}

sub get {
	my $self = shift;
	my $from = shift;
	my $sth  = $self->select( $from, ['*'], @_ );
	my $row  = $sth->fetchrow_hashref();
}

sub update {
	my $self = shift;
	my ( $s, @p ) = $self->sqla->update( @_ );
	return $self->_shared_query( $s, \@p );
}

sub insert {
	my $self = shift;
	my ( $s, @p ) = $self->sqla->insert( @_ );
	return $self->_shared_query( $s, \@p );
}

sub delete {
	my $self = shift;
	my ( $s, @p ) = $self->sqla->delete( @_ );
	return $self->_shared_query( $s, \@p );
}

sub _shared_query {
	my ( $self, $Q, $P ) = @_;
	$P ||= [];
	my $sth = $self->dbh->prepare( $Q ) or die "failed to prepare statement :/";
	try {
		$sth->execute( @{$P} ) or die $!;
	} catch {
		require Data::Dumper;
		require Carp;
		Carp::confess( "Failed to execute ($Q) with parameters" . Data::Dumper::Dumper( \@{$P} ) );
	};
	return $sth;
}

sub _build_abstract {
	require SQL::Abstract;
	return SQL::Abstract->new();
}
1;
