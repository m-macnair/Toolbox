#!/usr/bin/perl
#ABSTRACT:
our $VERSION = 'v0.0.2';

##~ DIGEST : 778c0aa665f47981eb775e0019f1e3cd

use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI'; #provides  CLI, FileSystem, Common
with qw//;

sub process {
	my ( $self, $path ) = @_;
	$path = $self->abs_path( $path );
	my $new_path = $self->snake_percent_file( $path );
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
