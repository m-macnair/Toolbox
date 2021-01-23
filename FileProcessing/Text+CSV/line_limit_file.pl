#!/usr/bin/perl
# ABSTRACT: split a file into smaller files based on maximum lines
our $VERSION = 'v0.0.2';

##~ DIGEST : f057e173ba10f6a8548f3aec595ecc3a

use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI'; #provides  CLI, FileSystem, Common
with qw/
  Moo::GenericRole::FileSystem
  Moo::GenericRole::FileIO
  Moo::GenericRole::FileIO::CSV

  /;
has _something => (
	is      => 'rw',
	lazy    => 1,
	default => sub { return }
);

sub process {
	my ( $self ) = @_;

	my $file_counter = 1;
	my $line_counter = 1;
	$self->sub_on_file_lines(
		sub {
			my ( $line ) = @_;
			my $ofh = $self->ofh( $self->cfg->{in_file} . "_$file_counter" );
			print $ofh $line;
			$line_counter++;
			if ( $line_counter > $self->cfg->{max_lines} ) {
				$self->close_fhs( [ $self->cfg->{in_file} . "_$file_counter" ] );
				$file_counter++;
				$line_counter = 1;
			}

			return 1;
		},
		$self->cfg->{in_file}
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
			  in_file
			  max_lines
			  /
		],
		[qw//],
		{
			required => {
				in_file   => 'File to process',
				max_lines => 'Maximum lines per file',

			},
			optional => {}
		}
	);
	$self->process();

}
