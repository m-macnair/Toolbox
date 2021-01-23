#!/usr/bin/perl
# ABSTRACT: trigger parallel mysql import commands on a list of .sql files
our $VERSION = 'v0.0.16';
##~ DIGEST : 6cfc3d902a15135f065a31d044d4837e
use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI'; #provides CLI, FileSystem, Common
with qw/
  Moo::GenericRole::FileSystem
  Moo::GenericRole::FileIO
  Moo::GenericRole::FileIO::CSV
  Moo::GenericRole::JSON
  Moo::GenericRole::DB
  Moo::GenericRole::DB::Abstract
  Moo::GenericRole::DB::MariaMysql
  Moo::GenericRole::DB::SQLite
  /;

sub process {

	my ( $self ) = @_;

	#confirms we can actually connect
	my $db_conf = $self->json_load_file( $self->cfg->{db_def_file} );
	$self->set_dbh_from_def( $db_conf );
	$self->dbh->disconnect();
	my $tmp_root = $self->cfg->{output_root} || './parallel_import/';
	unless ( -d $tmp_root ) {
		$self->make_path( $tmp_root );
	}
	$self->tmp_root( $tmp_root );
	my $file_counter = 1;
	$self->sub_on_csv(
		sub {
			my ( $row ) = @_;
			unless ( $row->[0] ) {
				warn "skipping empty row";
				return 1;
			}
			$self->aref_to_csv( [ $file_counter, $row->[0] ], $self->tmp_dir . '/manifest.csv' );
			my $log_path = $self->tmp_dir . "/$file_counter.log";
			$self->check_file( $row->[0] );
			my $cstring = qq|mysql  -A -h $db_conf->{host} -p -u $db_conf->{user} -p'$db_conf->{pass}' $db_conf->{db} < $row->[0] > $log_path 2>&1|;
			$cstring .= " &" if $self->cfg->{background};
			if ( $self->cfg->{live} ) {
				print `echo "$file_counter " &&  $cstring`;
			} else {
				print qq|echo "$file_counter " &&  $cstring$/|;
			}
			$file_counter++;
			return 1;
		},
		$self->cfg->{in_file}
	);
	$self->close_fhs();
	print "output in : " . $self->tmp_dir . $/;

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
			  in_file
			  /
		],
		[
			qw/
			  output_root
			  live
			  background
			  /
		],
		{
			required => {
				db_def_file => "JSON file containing database connection details",
				in_file     => "Path to .csv with paths of target sql files",
			},
			optional => {
				output_root => "Explict path for logs & mappings (default ./parallel_import/)",
				live        => "carry out the shell commands instead of printing them to stdout ",
				background  => "call the shell command and make it a background process (omit for linear processing) ",
			}
		}
	);
	$self->process();

}
