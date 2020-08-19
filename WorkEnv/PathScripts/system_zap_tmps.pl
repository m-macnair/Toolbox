#!/usr/bin/perl
# Maintain a clean /tmp/
use strict;
use warnings;
use File::Find;

#pass in space separated directories, or nothing in which case /tmp/ and known user temps will be used
main( @ARGV );

sub main {

	my @dirs;
	unless ( @dirs ) {
		push( @dirs, '/tmp/' );
		if ( index( $ENV{HOME}, 'root' ) == -1 ) {
			JUSTERASE: {
				for my $home_dir (
					qw#
					.cache/chromium/Default/Cache/
					.cache/mozilla/firefox/*/cache2/*
					.kde/cache-*/krun/*
					.kde/cache-*/favicons/*
					.kde/cache-*/http/*
					.kde/share/apps/gwenview/recentfolders/*
					.kde/share/apps/kfileplaces/*
					.kde/share/apps/klipper/*
					.kde/share/apps/okular/docdata/*
					.kde/share/config/session/*
					.kde/share/apps/RecentDocuments/*
					.kde/share/apps/plasma-desktop/activities/*
					.thumbnails/
					#
				  )
				{
					print "Clearing $ENV{HOME}/$home_dir$/";
					`rm -Rf $ENV{HOME}/$home_dir`;
				}
			}
			ERASEOLD: {
				my $age = 30;
				for my $home_dir (
					qw#
					.nv/GLCache/
					#
				  )
				{
					push( @dirs, [ "$ENV{HOME}/$home_dir", $age ] );
				}
			}
		}
	}
	`rm -Rf /tmp/slpkg/`;
	`rm -Rf /tmp/SBo/`;
	`rm -Rf /var/tmp/kdecache-*/krun/*`;
	for my $d ( @dirs ) {
		if ( ref( $d ) ) {
			process_tmp( @{$d} );
		} else {
			process_tmp( $d );
		}
	}

}

sub process_tmp {

	my ( $dir, $age ) = @_;
	warn $age;
	die "[$dir] is not a directory" unless ( -d $dir );
	require File::Find;
	File::Find::find(
		{
			wanted => sub {
				my $path = $File::Find::name;
				return if -l ( $path );

				#active tmps
				return                             if ( -M $path ) < 1;
				return process_dir( $path )        if -d ( $path );
				return process_file( $path, $age ) if -f ( $path );
				warn "No idea what to do with $path";
			},
			no_chdir => 1,
			follow   => 0,
		},
		$dir
	);

	# delete now empty directories
	`find $dir -type d -depth -empty -delete`;

}

sub process_file {

	my ( $path, $age ) = @_;
	$age ||= 365;

	#delete files over a year old
	if ( ( -M $path ) > $age ) {
		unlink $path;
		return;
	}

	#zap useless/no longer useful files
	for my $filetype (
		qw/
		.tgz
		.txz
		/
	  )
	{
		if ( lc( substr( $path, -length( $filetype ) ) ) eq lc( $filetype ) ) {
			unlink( $path );
			return;
		}
	}

}

# specific directory handling for /tmp/
sub process_dir {

	my ( $path ) = @_;

	#week old calc/libreoffice temp directories
	if ( lc( substr( $path, 4 ) ) eq '.tmp' ) {
		if ( ( -M $path ) > 7 ) {
			unlink $path;
			return;
		}
	}

}

sub del_if_e {

	my ( $path ) = @_;
	return unless $path;
	`rm -Rf $path` if -e $path;

}
