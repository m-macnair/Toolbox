#!/usr/bin/perl
# ABSTRACT: distribute each line in a file round robin over $n files
our $VERSION = 'v0.0.3';

##~ DIGEST : 190ba49e45b634143aaa10e1dde136a3

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

	my $pointer = 1;
	$self->sub_on_file_lines(
		sub {
			my ( $line ) = @_;
			my $ofh = $self->ofh( $self->cfg->{in_file} . "_$pointer" );
			print $ofh $line;
			$pointer++;
			$pointer = 1 if $pointer > $self->cfg->{max_files};
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
			  max_files
			  /
		],
		[
			qw/

			/
		],
		{
			required => {
				in_file   => 'File to process',
				max_files => 'Number of output files to create',

			},
			optional => {}
		}
	);
	$self->process();

}
