#!/usr/bin/perl
use strict;
use warnings;

#create a repo the way I like 'em - which is likely to change drastically in due course
use Cwd;
use File::Find;
use File::Basename;
use Toolbox::FileSystem @Toolbox::FileSystem::EXPORT_OK;
main( @ARGV );

sub main {
	my ( $target ) = @_;
	$target ||= './';

	my $tdir = gettemplates();

	print `cp -ruv $tdir/RepoStructure/* $target`;

}

sub gettemplates {

	my $thisfile = Cwd::abs_path( __FILE__ );
	my $thisdir  = File::Basename::dirname( $thisfile );
	my $tdir     = abspath( "$thisdir/../../Templates/" );
	die "template directory [$tdir] not found " unless -d $tdir;
	return $tdir;
}
