#!/usr/bin/perl
use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI';
with qw/
  Moo::GenericRole::DB
  Moo::GenericRole::DB::MariaMysql
  Moo::GenericRole::FileIO
  Moo::GenericRole::FileSystem
  Moo::GenericRole::JSON
  /;
ACCESSORS: {
	has columns => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			{}
		}
	);
}

sub process {

	my ( $self ) = @_;
	$self->json->pretty( 1 );
	$self->json->canonical( 1 );
	$self->process_database( $self->cfg->{path} );

}

sub process_database {

	my ( $self, $path ) = @_;
	$self->check_file( $path );
	my $table_dir   = $self->tmp_dir . '/' . $self->cfg->{database} . '/tables/';
	my $summary_dir = $self->tmp_dir . '/' . $self->cfg->{database} . '/summary/';
	$self->make_paths( [ $table_dir, $summary_dir ] );
	$self->sub_on_database_by_json_file(
		sub {
			$self->sub_on_db_tables(
				sub {
					my ( $table ) = @_;
					my $table_def = {table => $table};
					$self->sub_on_describe_table(
						sub {
							my ( $row_href ) = @_;
							$table_def->{fields}->{$row_href->{Field}} = $row_href;
							$self->columns->{$row_href->{Field}}++;
							return 1;
						},
						$table
					);
					$self->sub_on_show_table_index(
						sub {
							my ( $row_href ) = @_;
							push( @{$table_def->{'index'}}, $row_href );
							return 1;
						},
						$table
					);
					$self->json_write_href( "$table_dir/$table.json", $table_def );
					return 1;
				}
			);
		},
		$path,
		{
			driver   => 'mysql',
			user     => $self->cfg->{user},
			pass     => $self->cfg->{pass},
			database => $self->cfg->{database},
		}
	);
	$self->json_write_href( "$summary_dir/columns.json", $self->columns() );

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
			  pass
			  path
			  database
			  /
		],
		[
			qw/
			  out_path
			  /
		]
	);
	$obj->tmp_root( $obj->cfg->{out_path} || $obj->cfg->{database} );
	$obj->process();

}
