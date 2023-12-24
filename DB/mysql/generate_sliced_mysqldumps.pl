#!/usr/bin/perl
# ABSTRACT : given connection and a stack of tables, generate mysqldump commands to extract records based on stepped slices of the primary key assuming it's an auto increment
use strict;
use warnings;
use Carp qw/ cluck confess /;
use Data::Dumper;

package Obj;
use List::Util qw/any/;
use Moo;
ACCESSORS: {
	has dbh => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			my $self = shift;
			return $self->_set_dbh();
		}
	);
	has slice_size => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			10000;
		}
	);
}
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
	$self->aref_to_csv( [ '#table', 'start', 'command' ], './command_stack.csv' );
	$self->sub_on_csv(
		sub {
			my ( $row ) = @_;
			return $self->process_table( $row->[0], $self->cfg->{where}, );
		},
		$self->cfg->{in_file}
	);

}

sub process_table {

	my ( $self, $table, $where, $where_params ) = @_;
	$where        ||= '';
	$where_params ||= [];
	chomp( $table );
	$table =~ s| ||g;
	return 1 unless $table;
	my @dump_bits = (
		qw/
		  --net_buffer_length=4096
		  --no-create-info
		  --skip-add-locks
		  --skip-add-drop-table
		  --compact
		  --skip-disable-keys
		  --skip-set-charset
		  /
	);
	my $dump_string = join( ' ', @dump_bits );

	#this was a piece of absurdity to type
	my $dumpstring_where = '';
	if ( $where ) {
		$dumpstring_where = " and $where";
	}
	unless ( index( $where, 'where' ) != -1 ) { $where = "where $where" if $where }
	if     ( @{$self->check_table_for_columns( $table, ['id'] )} ) {
		my ( $max ) = $self->dbh->selectrow_array( "select max(id) from `$table` $where " );
		my ( $min ) = $self->dbh->selectrow_array( "select min(id) from `$table` $where " );
		for ( my $lower = $min ; $lower <= $max ; $lower += $self->slice_size() ) {
			my $upper        = $lower + $self->slice_size();
			my $where_string = qq|--where='id >= $lower and id < $upper $dumpstring_where '|;
			$self->aref_to_csv( [ $table, $lower, "$dump_string \t $where_string" ], './command_stack.csv' );
		}
	} else {
		$self->aref_to_csv( [$table], './no_id.csv' );
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
			  /,
		],
		[
			qw/
			  where
			  /
		]
	);
	$obj->criticalpath();

}
