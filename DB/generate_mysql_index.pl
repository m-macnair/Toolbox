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
  Moo::GenericRole::DB
  Moo::GenericRole::CombinedCLI
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
	my $wanted   = [ split( ',', $self->cfg->{column_string} ) ];
	my ( $tq )   = $self->dbh->prepare( "show tables" );
	$tq->execute();
	while ( my $tablerow = $tq->fetchrow_arrayref() ) {
		my @failures;
		my ( $idxsth ) = $self->dbh->prepare( "show indexes from `$tablerow->[0]`" );
		$idxsth->execute();
		my $indexmap = $idxsth->fetchall_hashref( 'Column_name' );
		my ( $columnsth ) = $self->dbh->prepare( "describe `$tablerow->[0]`" );
		$columnsth->execute();

		#go through the full description of each row for anything that resembles an index state
		while ( my $columndetailrow = $columnsth->fetchrow_hashref() ) {

			#it's possible something will be in a compound index - this may not be desirable in some cases
			if ( any { $_ eq $columndetailrow->{Field} } @{$wanted} ) {
				unless ( $indexmap->{$columndetailrow->{Field}} ) {
					push( @failures, $columndetailrow->{Field} );
				}
			}
		}
		if ( @failures ) {
			print "#$tablerow->[0]$/";
			for my $missing ( @failures ) {
				print "create index $missing\_index on `$tablerow->[0]`($missing);$/";
			}
		}
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
