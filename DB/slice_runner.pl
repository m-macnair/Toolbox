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
  Moo::GenericRole::FileIO
  Moo::GenericRole::FileIO::CSV
  /;
has mysqldump => (
	is      => 'rw',
	lazy    => 1,
	default => sub { 'mysqldump' }
);

sub criticalpath {

	my ( $self ) = @_;
	warn $self->cfg->{in_file};
	use Data::Dumper;
	$self->sub_on_csv(
		sub {
			my $v = shift;
			my ( $table, $start, $command ) = @{$v};
			my $file_name   = "$table\_$start.sql";
			my $dump_string = $self->mysqldump_string(
				{
					%{$self->cfg()}, table => $table,
				},
				[$command]
			) . " > $file_name";
			`$dump_string`;
			unless ( -s $file_name > 3 ) {
				unlink( $file_name );
			}
			return 1;
		},
		$self->cfg->{in_file}
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
			  in_file
			  /,
		],
		[]
	);
	$obj->criticalpath();

}
