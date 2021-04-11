#!/usr/bin/perl
# ABSTRACT: Given a db def and a csv of column names, go through the db, identify which of the named columns in tables are not indexed, and create the sql commands to remedy
our $VERSION = 'v0.0.3';
##~ DIGEST : 6c4131f65bcda35f82685fd64ad57744
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
  Moo::GenericRole::DB::Abstract
  Moo::GenericRole::DB::MariaMysql
  Moo::GenericRole::DB::SQLite
  /;

sub process {

	my ($self) = @_;
	$self->set_dbh_from_def( $self->json_load_file( $self->cfg->{db_def_file} ) );
	my $columns;
	if($self->cfg->{column_file}){
		$columns = $self->get_csv_column( $self->cfg->{column_file} );
	} else { 
		$columns = split(',',$self->cfg->{these_columns});
	}
	for my $table ( @{ $self->dbh->selectcol_arrayref("show tables") } ) {

		#check for relevant columns
		my @found_columns;
		$self->sub_on_describe_table(
			sub {
				my ($row) = @_;
				for my $trigger_column ( @{$columns} ) {
					if ( $row->{Field} eq $trigger_column ) {
						push ( @found_columns, $trigger_column );
					}
				}
				return 1;
			},
			$table
		);
		if (@found_columns) {
			my $found_indexes   = {};
			my $missing_indexes = {};
			my $index_sth       = $self->dbh->prepare("show indexes from $table");
			$index_sth->execute();

			#each index
			while ( my $index_row = $index_sth->fetchrow_hashref() ) {
				for my $trigger_column (@found_columns) {

					#skip found
					next if $found_indexes->{$trigger_column};

					#detect if in any kind of index
					if ( $index_row->{Column_name} eq $trigger_column ) {
						if ( $self->cfg->{force} ) {

							#detect if already in use as the first column of an index, in which case we don't care if it's composite
							if ( $index_row->{Seq_in_index} != 1 ) {
								$found_indexes->{$trigger_column} = 1;
							}
						} else {

							#it's an index; good enough
							$found_indexes->{$trigger_column} = 1;
						}
					}
				}
			}
			for my $trigger_column (@found_columns) {
				next if $found_indexes->{$trigger_column};
				print "CREATE INDEX $trigger_column ON $table ($trigger_column);$/";
			}
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
			  
			  db_def_file
			  /,
			  [qw/ column_file  these_columns/]
		],
		[
			qw/
			  
			  any
			  /
		],
		{
			required => {
				db_def_file => "JSON file containing database connection details",
				column_file => "CSV style file with list of column names",
			},
			optional => {
				out_file => "Explicit output file path",
				force    => "Create a single column index even if the found columns are part of a composite index"
			}
		}
	);
	$self->process();

}
