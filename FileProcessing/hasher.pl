#!/usr/bin/perl
# ABSTRACT: generate CSV of path, file size and hashes for all files in a directory
use strict;
use warnings;
our $VERSION = 'v0.0.4';
##~ DIGEST : 2ed4d7a78507a33af726ffecd86f2293
use Data::Dumper;

BEGIN {
	push( @INC, "./lib/" );
	push( @INC, "../lib/" );
}

package Obj;
use List::MoreUtils qw(uniq);
use Moo;
use parent qw/

  Moo::GenericRoleClass::CLI
  /; #provides  CLI, FileSystem, Common

# with qw/ /;

sub get_hashes_for_file {
	my ( $self, $path ) = @_;

	$path = $self->abs_path( $path );
	my $md5_cmd  = qq<md5sum "$path" | awk '{ print \$1 }'>;
	my $sha1_cmd = qq<sha1sum "$path" | awk '{ print \$1 }'>;
	my $ed2k_cmd = qq<ed2k_hash "$path" >;

	my $md5_sum  = `$md5_cmd`;
	my $sha1_sum = `$sha1_cmd`;
	my $ed2k_sum = `$ed2k_cmd`;

	my $size;
	chomp( $md5_sum, $sha1_sum, $ed2k_sum );
	my @ed2k = split( '\|', $ed2k_sum );

	$size     = $ed2k[3];
	$ed2k_sum = $ed2k[4];

	return {
		path => $path,
		size => $size,
		md5  => lc( $md5_sum ),
		sha1 => lc( $sha1_sum ),
		ed2k => lc( $ed2k_sum )
	};
}
1;

package main;

main( @ARGV );

sub main {
	my ( $path ) = @_;
	my $self = Obj->new();
	use Data::Dumper;
	print Dumper( $self->get_hashes_for_file( $path ) );

}
