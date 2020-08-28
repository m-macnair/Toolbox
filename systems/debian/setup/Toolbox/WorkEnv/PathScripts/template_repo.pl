#!/usr/bin/perl
use strict;
use warnings;

#create a repo the way I like 'em - which is likely to change drastically in due course
use Toolbox::PathScripts;
main( @ARGV );

sub main {
	my ( $target ) = @_;
	$target ||= './';

	my $tdir = gettdir( __FILE__ );

	print `cp -ruv $tdir/RepoStructure/* $target`;
}
