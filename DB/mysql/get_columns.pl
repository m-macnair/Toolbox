#!/usr/bin/perl
# ABSTRACT: Given a db def, get every column name in a database
our $VERSION = 'v0.0.4';
##~ DIGEST : 0843384596c21cd6c1ce04fd09f0206c
use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI'; #provides  CLI, FileSystem, Common
with qw/
  Moo::GenericRole::FileIO
  Moo::GenericRole::FileIO::CSV
  Moo::GenericRole::JSON
  Moo::GenericRole::DB
  Moo::GenericRole::DB::Abstract
  Moo::GenericRole::DB::MariaMysql
  Moo::GenericRole::DB::SQLite
  /;

sub process {

	my ($self) = @_;
	$self->set_dbh_from_def( $self->json_load_file( $self->cfg->{db_def_file} ) );
	my $columns ={};
	for my $table ( @{ $self->dbh->selectcol_arrayref("show tables") } ) {
		$self->sub_on_describe_table(
			sub {
				my ($row) = @_;
				$columns->{ $row->{Field} }++;
				return 1;
			},
			$table
		);

	}
			my $out_file = $self->cfg->{out_file} || 'column_count.csv';
		for my $key ( sort ( keys ( %{$columns} ) ) ) {
			$self->aref_to_csv( [$key, $columns->{$key}],$out_file );
		}

}
1;

package main;
main();

sub main {

	my $self = Obj->new();
	$self->get_config( [
			qw/
			  db_def_file
			  /,
		],
		[
			qw/
			  outfile
			  /
		],
		{
			required => {
				db_def_file => "JSON file containing database connection details",
				column_file => "CSV style file with list of column names",
			},
			optional => {
				out_file => "Explicit output file path",
				force    => "Create a single column index even if the found columns are part of a composite index"
			}
		}
	);
	$self->process();

}
