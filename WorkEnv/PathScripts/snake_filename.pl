#!/usr/bin/perl
#ABSTRACT:
our $VERSION = 'v0.0.2';

##~ DIGEST : 710f2de1ab3305cdad192a7581791ebf

use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI'; #provides  CLI, FileSystem, Common
with qw//;

sub process {
	my ( $self, $path ) = @_;
	$path = $self->abs_path( $path );
	my $new_path = $self->snake_file( $path );
	if ( -e $new_path ) {
		die "Intended new path [$new_path] exists";
	}
	$self->mvf( $path, $new_path );
}
1;

package main;

main();

sub main {
	my $self = Obj->new();
	print $self->process( @ARGV );

}
