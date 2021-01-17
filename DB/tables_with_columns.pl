#!/usr/bin/perl
# ABSTRACT : given a csv of column names, return all table names with said column in a database
use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI';
use Time::HiRes;
use POSIX;
with qw/
  Moo::GenericRole::DB::MariaMysql
  Moo::GenericRole::DB
  Moo::GenericRole::JSON
  Moo::GenericRole::FileIO::CSV
  Moo::GenericRole::TimeHiRes
  /;
has source_db_conf => (
	is      => 'rw',
	lazy    => 1,
	default => sub { return {} }
);

sub process {

	my ( $self ) = @_;
	$self->source_db_conf( $self->json_load_file( $self->cfg->{source_db_conf} ) );
	my $column_list = $self->single_csv_to_arref( $self->cfg->{column_csv} );
	$self->dbh( $self->dbh_from_def( $self->source_db_conf() ) );
	my @return;
	$self->sub_on_db_tables(
		sub {
			my ( $table ) = @_;
			$self->sub_on_describe_table(
				sub {
					my ( $row_href ) = @_;
					for my $wanted ( @{$column_list} ) {
						if ( $wanted eq $row_href->{Field} ) {
							if ( $self->cfg->{print_fast} ) {
								print "$table$/";
							} else {
								push( @return, $table );
							}
						}
					}
				},
				$table
			);
		}
	);
	print join( $/, @return ) unless ( $self->cfg->{print_fast} );

}

=head3 floating_block_transfer
	From a great deal of parameters, transfer from source to target in gradually increasing increments until a specific time is hit
=cut

=head3 single_csv_to_arref

	turn $column from a csv into an array

=cut

sub single_csv_to_arref {

	my ( $self, $source, $c ) = @_;
	$c ||= {};
	my @return;
	my $column = $c->{column} || 0;
	$self->sub_on_csv(
		sub {
			my $row = shift;
			push( @return, $row->[$column] ) if $row->[$column];
		},
		$source
	);
	return \@return; #return!

}
1;

package main;
main();

sub main {

	my $obj = Obj->new();
	$obj->get_config(
		[qw/ source_db_conf column_csv /],
		[qw/print_fast/],
		{
			required => {
				source_db_conf => 'Source database connection details in json format',
				column_csv     => 'CSV file with list of desired columns',
			},
			optional => {print_fast => "Print guilty tables as they are found instead of all at once"}
		}
	);
	$obj->process();

}
