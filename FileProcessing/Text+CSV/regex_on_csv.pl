#!/usr/bin/perl
# ABSTRACT: given a regex and an input csv, apply the csv to each column
our $VERSION = 'v0.0.2';

##~ DIGEST : 7c357d3275acbdb9c7da7c2fb9555ed8

use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI'; #provides  CLI, FileSystem, Common
with qw/
  Moo::GenericRole::FileSystem
  Moo::GenericRole::FileIO
  Moo::GenericRole::FileIO::CSV

  Moo::GenericRole::JSON

  /;
has _something => (
	is      => 'rw',
	lazy    => 1,
	default => sub { return }
);

sub process {
	my ( $self ) = @_;
	$self->set_dbh_from_def( $self->json_load_file( $self->cfg->{db_def_file} ) );
	$self->sub_on_csv(
		sub {
			my ( $row ) = @_;
		},
		$self->cfg->{in_file}
	);
}
1;

package main;

main();

sub main {
	my $self = Obj->new();
	$self->get_config(
		[qw//],
		[
			qw/
			  in_file
			  out_file
			  db_def_file

			  /
		],
		{
			required => {},
			optional => {
				db_def_file => "JSON file containing database connection details",
				in_file     => "Path to input file",
				out_file    => "Explicit output file path",

			}
		}
	);
	$self->process();

}
