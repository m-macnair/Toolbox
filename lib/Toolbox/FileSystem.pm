use strict;
use warnings;
# ABSTRACT: common filesystem-y things
package Toolbox::FileSystem;
use Carp qw/ confess /;

use Exporter qw(import);
our @EXPORT_OK = qw(
	checkpath
	checkfile
	checkdir
	subonfiles
	filebasename
	mvf
	cpf
	abspath
);

=head3 checkpath
	Given a path and optionally the 'context name' of the variable that connects it, confirm presence or HCF
=cut

sub checkpath {
	my ($path,$vname) = @_;
	$vname = _vname($vname);
	confess("checkpath $vname value is null") unless $path;
	confess("checkpath $vname path [$path] does not exist") unless -e $path;
	return 1;

}


sub checkfile { 
	my ($path,$vname) = @_;
	$vname = _vname($vname);
	checkpath($path,$vname);
	confess("checkfile $vname path [$path] is not a file ") unless -f $path;
}

sub checkdir {
	my ($path,$vname) = @_;
	$vname = _vname($vname);
	checkpath($path,$vname);
	confess("checkdir $vname path [$path] is not a directory ") unless -d $path;

}

sub filebasename {
	my ($path) = @_;
	require File::Spec;
	my ($dev,$dir,$file) = File::Spec->splitpath($path);
	return ($file,$dir,$dev);
	
}

sub _vname  {
	my ($vname) = @_;
	unless  ($vname) {
		$vname = '';
	}
	return $vname 
}

sub mvf {

	my ($source,$target) = _shared_fc(@_);
	warn "[$source],[$target]";
	require File::Copy;
	File::Copy::mv($source,$target) or Carp::confess("move failed: $!");

}

sub cpf { 
	my ($source,$target) = _shared_fc(@_);
	require File::Copy;
	File::Copy::cp($source,$target) or Carp::confess("copy failed: $!");
}

sub _shared_fc { 
	my ($source,$target) = @_;
	$source = abspath($source);
	$target = abspath($target);
	return ($source,$target);
}



sub abspath {

	my ($path) = @_;
	my $return;
	if (-e $path) {
		require Cwd;
		$return = Cwd::abs_path($path);
		if (-d $return) {
			$return .= '/';
		}
	} else {
		require File::Spec;
		$return = File::Spec->rel2abs($path);
	}
	return $return; #return!

}


sub subonfiles {
	my ( $sub,$dir) = @_;
	require File::Find::Rule;
	confess("First parameter to subonfiles was not a code reference") unless ref($sub) eq 'CODE';
	checkdir($dir,'subonfiles directory');
	my @files = File::Find::Rule->file()->in($dir);
	my $continue ;
	for(@files){
		next unless ( index(lc($_),'.mp3') != -1 );
		$continue = &$sub($_);
		last unless $continue;
	}
}

1;