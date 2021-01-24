#!/usr/bin/perl
# ABSTRACT: given  files $a and $b - produce a 3rd file of lines in $a that are not in $b
our $VERSION = 'v0.0.4';

##~ DIGEST : 99cdb1b12a3052313b76a36c5c36dcd8

use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI'; #provides  CLI, FileSystem, Common
with qw/
  Moo::GenericRole::FileIO

  /;
use List::Util qw/any/;

sub process {
	my ( $self ) = @_;
	my $compare_map = {};
	$self->sub_on_file_lines(
		sub {
			my ( $line ) = @_;
			chomp( $line );
			$compare_map->{$line} = 1;
		},
		$self->cfg->{compare}
	);

	my $ofh = $self->ofh( $self->cfg->{out_file} || 'missing_in_file_' . $self->iso_time_string . '.txt' );
	$self->sub_on_file_lines(
		sub {
			my ( $line ) = @_;
			chomp( $line );
			unless ( $compare_map->{$line} ) {
				print $ofh "$line$/";
			}
		},
		$self->cfg->{source}
	);
	$self->close_fhs();

}
1;

package main;

main();

sub main {
	my $self = Obj->new();
	$self->get_config(
		[
			qw/
			  source
			  compare
			  /
		],
		[
			qw/

			  out_file

			  /
		],
		{
			required => {
				source  => "Master file",
				compare => "File to check for missing elements",
			},
			optional => {

				out_file => "Explicit output file path",

			}
		}
	);
	$self->process();

}
