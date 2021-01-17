#!/usr/bin/perl
# ABSTRACT : given a dsn, and either a string or file of index needing columns, create the statements to ammend the database with missing indices
use strict;
use warnings;
use Carp qw/ cluck confess /;
use Data::Dumper;

package Obj;
use List::Util qw/any/;
use Moo;
with qw/
  Moo::GenericRole::CombinedCLI
  Moo::GenericRole::DB
  Moo::GenericRole::DB::MariaMysql
  Moo::GenericRole::FileSystem
  /;
has mysqldump => (
	is      => 'rw',
	lazy    => 1,
	default => sub { 'mysqldump' }
);

sub criticalpath {

	my ( $self ) = @_;
	use Data::Dumper;
	$self->sub_on_files(
		sub {
			my ( $path ) = @_;
			my $cmd_string = $self->mysql_cli_string( {%{$self->cfg()},}, [] ) . " < $path";

			# 			warn $cmd_string;
			`$cmd_string`;
			return 1;
		},
		$self->cfg->{in_dir}
	);

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
			  pass
			  in_dir

			  /,
		],
		[qw/out_dir/]
	);
	$obj->criticalpath();

}
