#!/usr/bin/perl
# ABSTRACT:
our $VERSION = 'v0.0.1';

##~ DIGEST : 0a842c7a43fe095742b16052fe2f80ec

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
  
  Moo::GenericRole::DB::MariaMysql
  

  /;

sub process {
	my ( $self ) = @_;
	
	$self->set_dbh_from_def(  $self->json_load_file( $self->cfg->{db_def_file} ) );

	
	my $wanted = [ split( ',', $self->cfg->{column_string} ) ];
	
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
	my $self = Obj->new();
	$self->get_config(
		[
			qw/
			  db_def_file
			  column_string
			  /,
		],
		[],
		{
			required => {
				db_def_file => 'json document with database connection details',
				column_string => 'comma separated list of columns to find',

			},
			optional => {}
		}
	);
	$self->process();

}
