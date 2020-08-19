#!/usr/bin/perl
# ABSTRACT : Given two directories, hash all files in both, and delete any files in the second directory that match hashes found in the first directory
use strict;
use warnings;
use Digest::MD5;
use File::Find::Rule;
main( @ARGV );

sub main {

	my ( $safe, $burn ) = @_;
	die "First Argument, Safe directory [$safe] is not a directory"  unless ( -d $safe );
	die "Second Argument, Burn directory [$burn] is not a directory" unless ( -d $burn );
	die "Same directory provided twice!"                             unless ( $safe ne $burn );
	my @safelist = File::Find::Rule->file()->in( $safe );
	my @burnlist = File::Find::Rule->file()->in( $burn );
	my $safemap  = listtomap( \@safelist );
	my $burnmap  = listtomap( \@burnlist );

	for my $kept ( keys( %{$safemap} ) ) {
		if ( $burnmap->{$kept} ) {
			for my $burnfile ( @{$burnmap->{$kept}} ) {
				unlink( $burnfile );
			}
		}
	}

}

sub listtomap {

	my ( $listarref ) = @_;
	my $return;
	for my $file ( @{$listarref} ) {
		my $digest = md5binfile( $file )->{pass};
		push( @{$return->{$digest}}, $file );
	}
	return $return; #return!

}

sub md5binfile {

	my ( $file ) = @_;
	open( my $fh, '<', $file ) or return {fail => "Can't open [$file]: $!"};
	binmode( $fh );
	my $md5 = Digest::MD5->new;
	while ( <$fh> ) {
		$md5->add( $_ );
	}
	close( $fh );
	return {pass => $md5->digest, md5o => $md5};

}

sub md5hexfile {

	my ( $file ) = @_;
	my $result = md5binfile( $file );
	return $result unless $result->{pass};
	return {pass => $result->{pass}->hexdigest(), m5o => $result->{pass}};

}
