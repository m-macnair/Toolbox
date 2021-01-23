#!/usr/bin/perl
# ABSTRACT:
our $VERSION = 'v0.0.3';
##~ DIGEST : 2bb6cf4b972c99a51a0a218a16ef9cc1
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

sub process {

	my ( $self ) = @_;
	my $db_conf = $self->json_load_file( $self->cfg->{db_def_file} );
	$self->sub_on_csv(
		sub {
			my ( $row ) = @_;
			my $cstring = qq|mysql  -A -h $db_conf->{host} -p -u $db_conf->{user} -p'$db_conf->{pass}' $db_conf->{db} < $row->[0]|;
			print "$cstring$/";
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
		[
			qw/
			  in_file
			  db_def_file
			  /
		],
		[
			qw/
			  /
		],
		{
			required => {
				db_def_file => "JSON file containing database connection details",
				in_file     => "Path to input file",
			},
			optional => {}
		}
	);
	$self->process();

}
