#!/usr/bin/perl
# ABSTRACT : A web page to sort files in the current directory

our $VERSION = 'v1.0.5';

##~ DIGEST : b6468313287b5d5eb152e4711d9bda2a
use strict;

use warnings;
use lib qw{
  /home/m/git/Toolbox-lib/lib/
  /home/m/git/Moo-GenericRole/lib/

};
use CGI;
use File::Find::Rule;

use Toolbox::Class::JSDispatch;
use Moo::GenericRole::FileSystem;
use Toolbox::FileSystem;
use JSON;
use Data::Dumper;
use File::Path;
use File::Copy;
use Try::Tiny;
use URI::Encode qw(uri_encode uri_decode);
use List::Util qw(any);
my $img_types = [
	qw/
	  jpg
	  png
	  gif
	  jpeg
	  webp
	  /
];
my $video_types = [
	qw/
	  mp4
	  webm

	  /
];

main();

sub main {
	my $cgi    = CGI->new();
	my $action = $cgi->param( 'action' ) || '';

	print $cgi->header();
	unless ( $action ) {
		defaultaction();
		exit;
	}
	try {
		for my $safeaction (
			qw/
			move
			/
		  )
		{

			if ( $action eq $safeaction ) {

				no strict 'refs';
				my $safeaction = "ka$safeaction";
				print &$safeaction( $cgi );
				return;
			} else {
				warn "$action ne $safeaction";
			}
		}
	} catch {
		print "Unhandled error: $_";
		exit;
	};
	die "fell out of loop";
}

sub defaultaction {
	my $file = _getfile( './' );
	unless ( $file ) {
		print "Nothing else to do$/";
		exit;
	}
	my $jsd = Toolbox::Class::JSDispatch->new(
		{
			extra_outboundrequest_success => qq#location.reload();#

		}
	);
	my $map = _parsemap( "./keymap.json", "&file=$file" );
	my $ui  = $jsd->generateinterface(
		{
			urlmap       => $map,
			jsformapconf => {

				#the == shouldn't work apparently

			}
		}
	);
	my @keyhelperstack;
	for my $key ( sort( keys( %{$map} ) ) ) {
		my ( $target ) = ( $map->{$key} =~ m|target=([^&]*)&| );
		push( @keyhelperstack, "<span> $key > $target </span>" );
	}
	my $keyhelperstring = join( '|', @keyhelperstack );
	my $fileurl         = uri_encode( $file );

	my ( $name, $dir, $suffix ) = file_parse( $file );
	if ( any { ".$_" eq $suffix } @{$video_types} ) {
		print qq|
			<html>
				<body style="background-color:black;height:100%;width:100%;">
					<div style="color:white">
					$keyhelperstring
					</div>
					<video src="$fileurl" controls autoplay>
						Your browser does not support the video tag.
					</video> 
					<script>
					$ui
					</script>
				</body>
			</html>
		|;

	} else {
		print qq|
			<html>
				<body style="background-color:black;height:100%;width:100%;">
					<div style="color:white">
					$keyhelperstring
					</div>
					<img src="$fileurl" style="min-height:90%;max-width:100%">
					<script>
					$ui
					</script>
				</body>
			</html>
		|;
	}

}

sub kamove {
	my ( $cgi ) = @_;

	#list context vulnerablity apparently
	my $file = $cgi->param( 'file' );
	$file = uri_decode( $file );
	my $target = $cgi->param( 'target' );
	if ( index( $file, '..' ) != -1 ) {
		confess( "Trying to do something with relative source paths [$file] " );
	}

	if ( index( $target, '.' ) != -1 ) {
		confess( "Trying to do something with relative or hidden target paths [$target] " );
	}
	$target =~ s|/||g;

	my ( $dir ) = _relative_to_here();
	$target = "$dir/$target";

	my $actual_file = Toolbox::FileSystem::abspath( "$dir/$file" );
	my $exists;

	# TODO create directory automatically
	unless ( -d $target ) {
		Toolbox::FileSystem::mkpath( Toolbox::FileSystem::abspath( $target ) );
	}
	try {
		Toolbox::FileSystem::safemvf( $actual_file, "$target/" );
	} catch {
		if ( index( $_, '] already exists' ) != -1 ) {
			$exists = 1;
			warn "existing file";
		} else {
			die "Unhandled error : $_";
		}

	};
	if ( $exists ) {
		my ( $name, $path, $suffix ) = File::Basename::fileparse( $actual_file, qr/\.[^.]*/ );
		require Data::UUID;
		my $ug         = Data::UUID->new;
		my $uuid       = $ug->to_string( $ug->create() );
		my $new_target = "$target/$name\_$uuid$suffix";

		warn "Pre-existing file - renamed to $new_target";
		Toolbox::FileSystem::safemvf( $actual_file, $new_target );
	}

	return "ok";

}

=head3 _parsemap
	Get the mapping file and make it useful
=cut

sub _parsemap {
	my ( $keymappath, $extra ) = @_;
	my $map = _loadjsonfile( $keymappath );

	if ( exists( $map->{replace} ) ) {
		for my $key ( keys( %{$map->{'map'}} ) ) {
			for my $replace ( keys( %{$map->{replace}} ) ) {
				$map->{'map'}->{$key} =~ s|$replace|$map->{replace}->{$replace}|g;
				$map->{'map'}->{$key} .= $extra;
			}
		}
		$map = $map->{'map'};
	} else {
		warn "no substitution detected - this is probably wrong";
	}

	return $map;
}

=head3 _getfile
	Detect the next file to work on
=cut

sub _getfile {
	my ( $dir ) = @_;
	$dir ||= './';
	my $found;
	opendir( DIR, $dir ) or die $!;
	my @files = sort( readdir( DIR ) );
	for my $file ( @files ) {
		next unless $file =~ m{^[\s\w\d\W % _ \)\(. ]*$};
		my ( $name, $path, $suffix ) = File::Basename::fileparse( $file, qr/\.[^.]*/ );
		for my $ftype ( @{$img_types}, @{$video_types} ) {
			if ( lc( $suffix ) eq ".$ftype" ) {
				$found = $file;
				last;
			}
		}
	}
	closedir( DIR );
	return $found;
}

sub _relative_to_here {
	my $thisfile = Cwd::abs_path( __FILE__ );
	my ( $dev, $thisdir, $file ) = File::Spec->splitpath( $thisfile );
	return ( $thisdir, $file );
}

sub _loadjsonfile {

	my ( $path ) = @_;
	my $jsonstring;
	open( my $ifh, "<:raw", $path ) or die( "failed to open [$path] $!" );
	while ( <$ifh> ) {
		$jsonstring .= $_;
	}
	close $ifh;

	return JSON::from_json( $jsonstring );

}

sub file_parse {
	my ( $path ) = @_;
	require File::Basename;
	my ( $name, $dir, $suffix ) = File::Basename::fileparse( $path, qr/\.[^.]*/ );
	return ( $name, $dir, $suffix );
}
