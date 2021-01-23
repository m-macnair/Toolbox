#!/usr/bin/perl
#ABSTRACT: given a connection definition and a csv file of table names, truncate each table (that exists) in the target database
our $VERSION = 'v0.0.4';
##~ DIGEST : 37c93894104d5881f3521d94ced9c3db
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
  /;
has mysql_table_exists_sth => (
	is      => 'rw',
	lazy    => 1,
	default => sub { my ( $self ) = @_; return $self->dbh->prepare( "SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ?" ); }
);

sub process {

	my ( $self ) = @_;
	my $check_sth = $self->dbh->prepare( "SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ?" );
	$self->sub_on_csv(
		sub {
			my ( $row ) = @_;
			$check_sth->execute( $row->[0] );
			if ( $check_sth->fetchrow_arrayref() ) {
				print "Truncating $row->[0]$/";
				$self->dbh->do( "TRUNCATE `$row->[0]`" ) or die $DBI::errstr;
			} else {
				print "Skipping absent table $row->[0]$/";
			}

			return 1;
		},
		$self->cfg->{table_csv}
	);

}

sub _set_dbh {

	my $self = shift;
	return $self->dbh_from_def( $self->json_load_file( $self->cfg->{db_def_file} ) );

}

sub table_exists {
	my ( $self, $table_name ) = @_;

	$self->mysql_table_exists_sth->execute( $table_name );
	return $self->mysql_table_exists_sth->fetchrow_arrayref();
}
1;

package main;
main();

sub main {

	my $obj = Obj->new();
	$obj->get_config(
		[qw/  db_def_file table_csv /],
		[],
		{
			required => {
				db_def_file => 'Source database connection details in json format',
				table_csv   => 'CSV file with list of tables to process',
			}
		}
	);
	$obj->process();

}
