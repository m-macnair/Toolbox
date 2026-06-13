#!/usr/bin/perl
use strict;
use warnings;
our $VERSION = 'v1.0.7';

##~ DIGEST : b59c35bdb25253025eec9e381770495d

use File::Find;
use File::Basename;
use File::Spec;
use Cwd 'abs_path';

my ( $start_dir ) = @ARGV;
die "start_dir not provied" unless -d $start_dir;
$start_dir = abs_path( $start_dir );

my $counter = 1;
my @stack;
find( \&wanted, $start_dir );

sub wanted {
	return unless -f $_;
	return unless /\.stl$/i;

	my $old_path = File::Spec->catfile( abs_path( $File::Find::dir ), $_ );
	push( @stack, $old_path );
}

for my $path ( sort( @stack ) ) {

	my ( $name, $dir, $suffix ) = fileparse( $path, qr/\.[^.]*/ );
	my $short_name = $name;
	$short_name =~ s/^(?:\d{4}_)+//;
	my $new_name = sprintf( '%04d_%s%s', $counter, $short_name, $suffix );
	my $new_path = File::Spec->catfile( $dir, $new_name );

	if ( -e $new_path ) {
		warn "Skipping: $new_path already exists.$/";
	} else {
		rename( $path, $new_path ) or warn "Failed to rename $path: $!$/";
		print "Renamed: $path -> $new_path$/";
		$counter++;
	}

}
