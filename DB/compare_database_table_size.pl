#!/usr/bin/perl
# ABSTRACT:
our $VERSION = 'v0.0.6';
##~ DIGEST : 9f2bec72185ddd0205601e2a332e7d52
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
  Moo::GenericRole::DB
  Moo::GenericRole::DB::Abstract
  Moo::GenericRole::DB::MariaMysql
  Moo::GenericRole::DB::SQLite
  Moo::GenericRole::UUID
  /;

sub process {

	my ($self)      = @_;
	my $master_dbh  = $self->dbh_from_def( $self->json_load_file( $self->cfg->{master_db_def} ) );
	my $subject_dbh = $self->dbh_from_def( $self->json_load_file( $self->cfg->{subject_db_def} ) );
	my @table_stack;
	if ( $self->cfg->{check_tables} ) {
		$self->sub_on_csv(
			sub {
				my ($row) = @_;
				push ( @table_stack, $row->[0] );
			},
			$self->cfg->{check_tables}
		);
	} else {
		my $table_list_query = $master_dbh->prepare("show tables");
		$table_list_query->execute();
		while ( my $row = $table_list_query->fetchrow_arrayref() ) {
			push ( @table_stack, $row->[0] );
		}
	}
	my $out_file = 'database_compare_' . $self->iso_time_string();
	$self->aref_to_csv( [qw/ table master subject  /], $out_file );
	for my $table (@table_stack) {
		my $master_sth = $master_dbh->prepare("select count(*) from `$table`");
		$master_sth->execute();
		my $master_row  = $master_sth->fetchrow_arrayref();
		my $subject_sth = $master_dbh->prepare("select count(*) from `$table`");
		$subject_sth->execute();
		my $subject_row = $subject_sth->fetchrow_arrayref();
		unless ( $master_row->[0] == $subject_row->[0] ) {
			$self->aref_to_csv( [$table, $master_row->[0], $subject_row->[0]], $out_file );
		}
	}

}
1;

package main;
main();

sub main {

	my $self = Obj->new();
	$self->get_config( [
			qw/
			  master_db_def
			  subject_db_def
			  /
		],
		[
			qw/
			  check_tables
			  /
		],
		{
			required => {
				master_db_def  => "The 'Right' database",
				subject_db_def => "The db to consider",
			},
			optional => {
				check_tables => "Specific set of tables to compare as opposed to 'all of them'",
			}
		}
	);
	$self->process();

}
