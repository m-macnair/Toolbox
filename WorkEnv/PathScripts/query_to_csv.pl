#!/usr/bin/perl
#ABSTRACT: given arbitrary sql and a json file defining the database connection, run the query and write the output to a csv file
our $VERSION = 'v1.0.1';

##~ DIGEST : bf8a4504aa9b2ca961643979a0954657
use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI';
with qw/
  Moo::GenericRole::FileIO
  Moo::GenericRole::FileIO::CSV
  Moo::GenericRole::DB
  Moo::GenericRole::JSON

  /;

sub process {
	my ( $self ) = @_;
	$self->set_dbh_from_def( $self->json_load_file( $self->cfg->{db_def_file} ) );
	my $sth = $self->dbh->prepare( $self->cfg->{query_string} );
	$sth->execute();

	my $out_file = $self->cfg->{out_file} || 'query_output_' . time . '.csv';
	$self->sth_href_to_csv( $sth, $out_file );
	print "$/Wrote to $out_file" unless ( $self->cfg->{out_file} );
	print "$/It is done. Move on!$/";
}
1;

package main;

main();

sub main {
	my $self = Obj->new();
	$self->get_config(
		[
			[
				qw/
				  file_query
				  query_string
				  /
			],
			qw/
			  db_def_file
			  /
		],
		[
			qw/
			  out_file
			  /
		],
		{
			required => {
				file_query   => 'Path to a file containing sql to execute',
				query_string => 'In line SQL to execute as the query',
				db_def_file  => 'Path to JSON file containing database connection definition',
			}

		}
	);

	if ( $self->cfg->{file_query} ) {
		$self->cfg->{query_string} = $self->slurp_file( $self->cfg->{file_query} );
	}

	$self->process();
}
