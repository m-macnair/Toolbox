#!/usr/bin/perl
# ABSTRACT: from maximum seconds of processing, optionally db(s) and optionally user(s), kill all corresponding mysql db processes
our $VERSION = 'v0.0.3';
##~ DIGEST : 2ca78352a94104f4cc88a37cd2636f42
use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI'; #provides  CLI, FileSystem, Common
with qw/
  Moo::GenericRole::JSON
  Moo::GenericRole::DB
  Moo::GenericRole::DB::Abstract
  Moo::GenericRole::DB::MariaMysql
  Moo::GenericRole::DB::SQLite
  /;

sub process {

	my ( $self ) = @_;
	$self->set_dbh_from_def( $self->json_load_file( $self->cfg->{db_def_file} ) );
	my $params = {TIME => {'>=' => $self->cfg->{max_time}}};
	for ( qw/USER DB / ) {
		if ( $self->cfg->{"opt_$_"} ) {
			my @v = split( ',', $self->cfg->{"opt_$_"} );
			$params->{$_} = \@v;
		}
	}
	use Data::Dumper;

	# 	die Dumper($params);
	my ( $sth ) = $self->select( "INFORMATION_SCHEMA.PROCESSLIST", ['*'], $params );

	while ( my $row = $sth->fetchrow_hashref() ) {
		print "Killing $row->{ID}$/";
		$self->query( "KILL $row->{ID}" );
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
			  max_time
			  db_def_file
			  /
		],
		[
			qw/
			  opt_USER
			  opt_DB
			  /
		],
		{}
	);
	$self->process();

}
