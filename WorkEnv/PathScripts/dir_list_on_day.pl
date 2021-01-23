#!/usr/bin/perl
# ABSTRACT: write a directory listing to the standard path with a time stamp - useful for tracking deletion on muh portable music players
our $VERSION = 'v0.0.2';

##~ DIGEST : fdbf61fb8f6a368740a49490e40cb758

use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI'; #provides  CLI, FileSystem, Common

sub process {
	my ( $self, $path ) = @_;
	$self->make_path( "/home/$ENV{USER}/ToolboxOutput/dir_list_on_day/" );
	$path = $self->abs_path( $path );
	my $path_string = $path;
	$path_string =~ s|/|_|g;
	my $target_dir = $self->make_path( "/home/$ENV{USER}/ToolboxOutput/dir_list_on_day/$path_string" );
	my $out_file   = $self->iso_time_string() . '.txt';
	print `find "$path" -type f > "$target_dir/$out_file"`;
	print "It is done. Move on!";
}
1;

package main;

main( @ARGV );

sub main {
	my $self = Obj->new();
	my ( $path ) = @_;
	$path ||= './';
	$self->process( $path );

}
