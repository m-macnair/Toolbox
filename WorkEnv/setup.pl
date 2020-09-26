#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
use File::Spec;
use File::Find;
use File::Basename;
main( @ARGV );

sub main {

	my $this_file = Cwd::abs_path( __FILE__ );
	my ( $dev, $this_dir, $file ) = File::Spec->splitpath( $this_file );

	#parent directory of this file's parent directory
	my $tbdir = Cwd::abs_path( dirname( $this_dir ) );

	#parent directory of this file's parent directory's parent directory
	my $git_dir = Cwd::abs_path( dirname( $tbdir ) );

	my @perllibs;

	GIT: {
		`git config --global credential.helper cache`;
		`git config --global credential.helper 'cache --timeout=36000'`;
		`chmod 0700 /home/$ENV{USER}/.git-credential-cache`;

		#clone my stuff and get ready to push the lib directory into the user's perl library stack
		push( @perllibs, get_repo_lib( $git_dir, 'https://github.com/m-macnair/Toolbox-lib.git',     'Toolbox-lib' ) );
		push( @perllibs, get_repo_lib( $git_dir, 'https://github.com/m-macnair/Moo-GenericRole.git', 'Moo-GenericRole' ) );

	}

	BASH: {
		BASHPROFILE: {
			unless ( -e "$ENV{HOME}/.bash_profile" ) {
				`touch "$ENV{HOME}/.bash_profile"`;
				`chmod +x  "$ENV{HOME}/.bash_profile"`;
				`echo "#!/bin/bash" > "$ENV{HOME}/.bash_profile"`;
			}

			`touch "$ENV{HOME}/.bashrc"` unless -e "$ENV{HOME}/.bashrc";

			add_unless( '.bashrc',                       "$ENV{HOME}/.bash_profile", 'source ~/' );
			add_unless( "$this_dir/Bash/bash_source.sh", "$ENV{HOME}/.bashrc",       'source ' );

		}

		#Construct a user agnostic bash source file that the user can append to their own; instead of zapping a perfectly good one
		BASHSOURCE: {

			#reset
			`echo 'export TOOLBOXDIR="$tbdir"' > $this_dir/Bash/bash_source.sh`;

			#append
			`echo 'export PATH="\$PATH:$this_dir/PathScripts"' >> $this_dir/Bash/bash_source.sh`;

			`cat $this_dir/Bash/bash_source_baseline.txt >> $this_dir/Bash/bash_source.sh`;

			PERLLIBS: {
				my $perllibstr = join( ':', @perllibs );
				`echo 'export PERL5LIB="\$PERL5LIB:$perllibstr"' >> $this_dir/Bash/bash_source.sh`;
			}
		}

		# TODO moar
	}

	PERL: {
		#connect perltidy if there isn't one already
		my $pt = "$ENV{HOME}/.perltidyrc";

		unless ( -e $pt ) {
			my $tpt = "$tbdir/perl/perltidyrc";
			if ( -e $tpt ) {
				Cwd::abs_path();
				my $linked = eval { symlink( $tpt, $pt ); 1 };
				die "Failed to softlink $tpt as $pt : $!" unless $linked;
			} else {
				warn "perltidyrc [$tpt] could not be found!";
			}
		}
	}

	KDE: {

		if ( -e "$ENV{HOME}/.kde" ) {
			KONSOLE: {
				File::Find::find(
					{
						wanted => sub {
							return unless -f $File::Find::name;
							link_in_dir_unless_exists( $File::Find::name, "$ENV{HOME}/.kde/share/apps/konsole/" );
						},
						no_chdir => 1,
						follow   => 0,
					},
					"$this_dir/KDE/konsole"
				);
			}

		}

	}
}

#not quite right but consistent

sub add_unless {
	my ( $string, $path, $string_prefix ) = @_;
	$string =~ s| |\ |g;
	unless ( `cat $path | grep $string ` ) {
		print `echo "$string_prefix$string" >> "$path"`;
	}
}

sub get_repo_lib {
	my ( $git_dir, $url, $name ) = @_;
	unless ( -e "$git_dir/$name" ) {
		`git clone $url $git_dir/$name`;
	}
	my $lib_path = "$git_dir/$name/lib/";
	unless ( -e $lib_path ) {
		die "Library path for $url [$lib_path] not found";
	}
	return $lib_path;
}

sub link_in_dir_unless_exists {
	my ( $source_file, $target_dir ) = @_;
	my ( $dev, $this_dir, $file ) = File::Spec->splitpath( $source_file );
	link_to_unless_exists( $source_file, "$target_dir/$file" );
}

sub link_to_unless_exists {
	my ( $source, $target ) = @_;

	# TIL -e doesn't catch softlinks
	unless ( -l $target || -e $target ) {
		`ln -s $source $target`;
	}
}

