use strict;
package Toolbox::FileList;
use Carp qw/confess /;
use File::Find::Rule;

sub subonfiles {
	my ( $sub,$dir) = @_;
	confess("Directory [$dir] not usable : $!") unless -d $dir;
	confess("First parameter to subonfiles was not a code reference") unless ref($sub) eq 'CODE';
	my @files = File::Find::Rule->file()->in($dir);
	my $continue ;
	for(@files){
		$continue = &$sub($_);
		last unless $continue;
	}

}

1;
