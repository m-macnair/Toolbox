#!/usr/bin/perl
# ABSTRACT : given connection and a stack of tables, return tables that have a row with column with a specific value
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
	$self->sub_on_csv(
		sub {
			my ( $row ) = @_;
			return $self->process_table( $row->[0] );
		},
		$self->cfg->{in_file}
	);

}

sub process_table {

	my ( $self, $table ) = @_;
	chomp( $table );
	$table =~ s| ||g;
	return 1 unless $table;
	print "[$table]$/";
	my ( $sth ) = $self->query( "select * from `$table` where " . $self->cfg->{column} . ' = ? limit 1', $self->cfg->{value} );
	if ( $sth->fetchrow_hashref() ) {
		$self->aref_to_csv( [ $table, $fetchrow_hashref->{id} ], "./owned_tables.csv" );
	}
	return 1;

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
			  in_file
			  column
			  value
			  /,
		],
		[]
	);
	$obj->criticalpath();

}
