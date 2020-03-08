use strict;
use warnings;

# ABSTRACT: common filesystem-y things
package Toolbox::FileSystem;
our $VERSION = '0.04';

##~ DIGEST : 6b2946ddc8e02096e6f36b22b8d2dc04
use Carp qw/ confess /;

use Exporter qw(import);
our @EXPORT_OK = qw(
  checkpath
  checkfile
  checkdir
  subonfiles
  filebasename
  mvf
  safemvf
  cpf
  abspath
  mkpath
);

=head3 checkpath
	Given a path and optionally the 'context name' of the variable that connects it, confirm presence or HCF
=cut

sub checkpath {
	my ( $path, $vname ) = @_;
	$vname = _vname( $vname );
	confess( "checkpath $vname value is null" ) unless $path;
	confess( "checkpath $vname path [$path] does not exist" ) unless -e $path;
	return 1;

}

sub checkfile {
	my ( $path, $vname ) = @_;
	$vname = _vname( $vname );
	checkpath( $path, $vname );
	confess( "checkfile $vname path [$path] is not a file " ) unless -f $path;
}

sub checkdir {
	my ( $path, $vname ) = @_;
	$vname = _vname( $vname );
	checkpath( $path, $vname );
	confess( "checkdir $vname path [$path] is not a directory " ) unless -d $path;

}

sub filebasename {
	my ( $path ) = @_;
	die "wrong method name";

	# 	require File::Spec;
	# 	my ( $dev, $dir, $file ) = File::Spec->splitpath( $path );
	# 	return ( $file, $dir, $dev );

}

sub filepathparts {
	my ( $path ) = @_;
	require File::Spec;
	my ( $dev, $dir, $file ) = File::Spec->splitpath( $path );
	return ( $file, $dir, $dev );
}

sub _vname {
	my ( $vname ) = @_;
	unless ( $vname ) {
		$vname = '';
	}
	return $vname;
}

sub mvf {

	my ( $source, $target ) = _shared_fc( @_ );

	require File::Copy;
	File::Copy::mv( $source, $target ) or confess( "move failed: $!" );

}

=head3 safemvf
	Move a file or else - in that it'll try and do everything what needs doing otherwise
=cut 

sub safemvf {

	my ( $source, $target ) = _shared_fc( @_ );

	#HCF if we're trying to move nothing
	checkfile( $source );
	my $target_dir;

	require File::Basename;
	my ( $name, $path, $suffix ) = File::Basename::fileparse( $source, qr/\.[^.]*/ );

	#Handle moving a file to a directory without an explicit file name
	if ( -d $target ) {

		$target = "$target/$name$suffix";
	} else {

		#only care about the directory here
		my ( undef, $target_dir, undef ) = File::Basename::fileparse( $target, qr/\.[^.]*/ );

		#does nothing if target directory exists already
		mkpath( $target_dir );
		$target = "$target_dir/$name$suffix";
	}

	#HFC if we're trying to overwrite
	if ( -e $target ) {
		Carp::confess( "safe target [$target] already exists" );
	}

	require File::Copy;
	File::Copy::mv( $source, $target_dir || $target ) or confess( "move failed: $!" );
	return 1;
}

sub cpf {
	my ( $source, $target ) = _shared_fc( @_ );
	require File::Copy;
	File::Copy::cp( $source, $target ) or confess( "copy failed: $!" );
}

=head3 mkpath
	make a directory path or die trying
=cut

sub mkpath {
	my ( $path ) = @_;
	confess "Path missing" unless $path;
	return $path if -d $path;
	require File::Path;
	my $errors;
	File::Path::make_path( $path, {error => \$errors} );
	if ( $errors && @{$errors} ) {
		my $errstr;
		for ( @{$errors} ) {
			$errstr .= $_ . $/;
		}
		confess( "[$path] creation failed : [$/$errstr]$/" );
	}

	#for when it's coming in as a string concat and the result is useful as a variable
	return $path;

}

sub _shared_fc {
	my ( $source, $target ) = @_;
	$source = abspath( $source );
	$target = abspath( $target );
	return ( $source, $target );
}

sub abspath {

	my ( $path ) = @_;
	my $return;
	if ( -e $path ) {
		require Cwd;
		$return = Cwd::abs_path( $path );
		if ( -d $return ) {
			$return .= '/';
		}
	} else {
		require File::Spec;
		$return = File::Spec->rel2abs( $path );
	}
	return $return; #return!

}

sub subonfiles {
	my ( $sub, $dir ) = @_;
	require File::Find::Rule;
	confess( "First parameter to subonfiles was not a code reference" )
	  unless ref( $sub ) eq 'CODE';
	checkdir( $dir, 'subonfiles directory' );
	my @files = File::Find::Rule->file()->in( $dir );
	my $stop;
	for ( @files ) {
		$stop = &$sub( abspath( $_ ) );
		last if $stop;
	}
}

1;
