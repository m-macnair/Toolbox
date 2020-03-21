use strict;
use warnings;

# ABSTRACT : things that are shared in the pathscripts, but don't make sense as modules
package Toolbox::PathScripts;
our $VERSION = 'v1.33.8';

##~ DIGEST : 61823874af03b3f04fb6510153b7aa62
use Toolbox::FileSystem @Toolbox::FileSystem::EXPORT_OK;
use File::Basename;
use Cwd;

#if we're using this module it's assumed we want everything from it, and the losses from not doing so are more than made up for in typing time
use Exporter qw(import);
our @EXPORT = qw(
  gettdir
  applytemplatefile
  usetemplatefile
);

sub usetemplatefile {

	my ( $cfile, $templatepath, $target ) = @_;
	$target ||= './';

	my $tdir = gettdir( $cfile );
	applytemplatefile( "$tdir/$templatepath", $target );

}

sub gettdir {
	my ( $rootfile ) = @_;
	my $thisfile     = Cwd::abs_path( $rootfile );
	my $thisdir      = File::Basename::dirname( $thisfile );
	my $tdir         = abspath( "$thisdir/../../Templates/" );
	die "template directory [$tdir] not found " unless -d $tdir;
	return $tdir;
}

sub applytemplatefile {
	my ( $source, $target ) = @_;
	if ( -f $target ) {
		my $backup = safemvf( $target, File::Basename::dirname( $target ), {mute => 1} );
		print `cp -ruv $source $target`;

	} elsif ( -d $target ) {
		print `cp -ruv $source $target`;
	} else {
		print `cp -ruv $source $target`;
	}
}

1;
