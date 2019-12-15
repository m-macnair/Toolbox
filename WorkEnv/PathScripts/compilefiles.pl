#!/usr/bin/perl
# ABSTRACT : Given two directories, hash all files in both, and delete any files in the second directory that match hashes found in the first directory
use strict;
use warnings;
use Data::Dumper;
use File::Find::Rule;
main( @ARGV );

sub main {
	my ( $include, $dir ) = @_;
	$dir ||= './';
	$include = '';
	die "Directory [$dir] is not a directory" unless ( -d $dir );

	my @safelist = File::Find::Rule->file()->name( "*.pm", "*.pl" )->in( $dir );

	for my $path ( @safelist ) {

		#news to me - perl -cw writes to stderr instead of stdout even on success
		#I suppose it makes sense from a generic executable perspective
		my $res = `perl $include -I lib -cw $path 2>&1`;
		unless ( index( $res, 'syntax OK' ) != -1 ) {

			print "failed : [$res]";
		}
	}

}
