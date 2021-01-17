#!/usr/bin/perl
# ABSTRACT : given a dsn, and either a string or file of index needing columns, create the statements to ammend the database with missing indices
use strict;
use warnings;
use Carp qw/ cluck confess /;
use Data::Dumper;

package Obj;
use List::Util qw/any/;
use Moo;
has dbh => (
	is      => 'rw',
	lazy    => 1,
	default => sub {
		my $self = shift;
		return $self->_set_dbh();
	}
);
with qw/
  Moo::GenericRole::FileIO
  Moo::GenericRole::FileIO::CSV
  Moo::GenericRole::DB
  Moo::GenericRole::CombinedCLI
  Moo::GenericRole::DB::MariaMysql
  /;

sub _set_dbh {

	my ( $self, $args ) = @_;
	$args ||= $self->cfg();
	my $driver = $args->{driver} || 'mysql';
	my $dbh    = DBI->connect( "dbi:$driver:$args->{db};host=$args->{host}", $args->{user}, $args->{pass}, $args->{dbattr} || {} ) or die $!;
	return $dbh;

}

sub criticalpath {

	my ( $self ) = @_;
	my $wanted = [ split( ',', $self->cfg->{column_string} ) ];
	use Data::Dumper;
	my $map = $self->check_db_for_columns( $wanted );
	$self->aref_to_csv( [ '#table', 'columns->' ], 'out.csv' );
	for my $table ( sort ( keys( %{$map} ) ) ) {
		$self->aref_to_csv( [ $table, @{$map->{$table}} ], 'out.csv' );
	}

}
1;

package main;
main();

sub main {

	my $obj = Obj->new();
	$obj->get_config(
		[
			qw/
			  user
			  db
			  host
			  driver
			  column_string
			  /,
		],
		[]
	);
	$obj->criticalpath();

}
