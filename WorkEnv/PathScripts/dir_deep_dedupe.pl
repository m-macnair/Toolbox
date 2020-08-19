#!/usr/bin/perl
use strict;
use warnings;
use Toolbox::Class::FileHashDB::Mk77;

# Given a directory, hash every file in it and delete all duplicates, keeping the deepest path file on the assumption it's the most organised
main( @ARGV );

sub main {

	my ( $path ) = @_;
	die "not risking a dedupe of working directory" unless $path;
	my $fhdb = Toolbox::Class::FileHashDB::Mk77->new();
	$fhdb->criticalpath3( $path );

}
