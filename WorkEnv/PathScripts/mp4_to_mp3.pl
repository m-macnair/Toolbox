#!/usr/bin/perl
#ABSTRACT: convert mp4 files to corresponding mp3 files
use strict;
use warnings;
use File::Find;
use File::Basename;

#pass in space separated directories, or nothing in which case /tmp/ and known user temps will be used
main( @ARGV );

sub main {
	my ( $file ) = @_;
	my ( $name, $path, $suffix ) = fileparse( $file, qr/\.[^.]*/ );
	print `ffmpeg -i "$file" -b:a 192K -vn "$name.mp3"`;

}
