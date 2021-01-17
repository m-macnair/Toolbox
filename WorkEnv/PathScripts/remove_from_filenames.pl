#!/usr/bin/perl
# ABSTRACT:
our $VERSION = 'v0.0.1';

##~ DIGEST : 8831af4301198dea1cfc67f0065bda7d

use strict;
use warnings;
require File::DosGlob;
use Data::Dumper;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI'; #provides  CLI, FileSystem, Common
with qw/
  Moo::GenericRole::FileSystem

  /;

sub process {
	my ( $self, $string, $paths ) = @_;
	die "No path(s) provided" unless ref( $paths ) eq 'ARRAY';

	die "String not provided" unless $string;
	for my $path ( @{$paths} ) {
		die "Path not provided" unless $path;
		return unless -f $path;
		$self->check_file( $path, "File to process" );
		if ( index( $path, $string ) != -1 ) {
			my ( $file_path, $dir ) = $self->file_path_parts( $path );
			my $new_file_path = $file_path;
			$new_file_path =~ s|$string||g;
			$self->safe_mvf( $path, $new_file_path );
		}
	}
}
1;

package main;

main();

sub main {
	my $self = Obj->new();
	my ( $string, $paths ) = $self->splice_glob_argv( 1 );
	$self->process( $string, $paths );

}
