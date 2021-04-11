#!/usr/bin/perl
# ABSTRACT: given two columns and two csv files, remove the instances where column $x cells from file A are in column $y cells in file B
our $VERSION = 'v0.0.2';

##~ DIGEST : 65e787649caa466829e5b6b57662644e

use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI'; #provides  CLI, FileSystem, Common
with qw/
  Moo::GenericRole::FileSystem
  Moo::GenericRole::FileIO
  Moo::GenericRole::FileIO::CSV

  Moo::GenericRo

  /;
use List::Util qw/any /;

sub process {
	my ( $self ) = @_;
	my @masking_columns;
	my $source_column = $self->cfg->{source_column} || 0;
	my $target_column = $self->cfg->{target_column} || 0;
	$self->sub_on_csv(
		sub {
			my ( $row ) = @_;
			push( @masking_columns, $row->[ $source_column ] );
		},
		$self->cfg->{source_file}
	);

	my $out_file = $self->cfg->{out_file} || "./remove_csv_from_csv_" . $self->iso_time_string . '.csv';
	my $reject_file;


	$self->sub_on_csv(
		sub {
			my ( $row ) = @_;
			my $v = $row->[ $target_column ];

			if ( any { $v eq $_ } @masking_columns ) {
				if ( $self->cfg->{reject_file} ) {
					$self->aref_to_csv( $row, $self->cfg->{reject_file} );
				}

			} else {
				$self->aref_to_csv( $row, $out_file );
			}
			return 1;
		},
		$self->cfg->{target_file}
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
			  source_file
			  target_file

			  /
		],
		[
			qw/
				source_column
			  target_column

			  out_file
			  /
		],
		{
			required => {
				source_file   => 'File with columns to mask in target file',
				target_file   => 'File with columns to mask',
			},
			optional => {
				source_column => 'Column from source_file to mask (default 0)',
				target_column => 'Column in target_file to be masked (default 0)',
			},
			optional => {
				out_file    => "Explicit output file name; defaults to remove_csv_from_csv_<isotime>.csv",
				reject_file => "If provided, write rejected lines to this file path"
			}
		}
	);
	$self->process();

}
