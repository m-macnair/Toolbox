#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
use File::Spec;
use File::Find;
use File::Basename;
main( @ARGV );

sub main {
	my ( $me ) = @_;
	$me ||= 'm';
	unless ( $me eq $ENV{USER} ) {
		warn "You are not $me - some actions will be skipped";
	}
	$me = $me eq $ENV{USER};
	my $thisfile = Cwd::abs_path( __FILE__ );
	my ( $dev, $thisdir, $file ) = File::Spec->splitpath( $thisfile );

	#parent directory of this file's parent directory
	my $tbdir = Cwd::abs_path( dirname( $thisdir ) );

	#parent directory of this file's parent directory's parent directory
	my $gitdir = Cwd::abs_path( dirname( $tbdir ) );

	my @perllibs;

	GIT: {
		`git config --global credential.helper cache`;
		`git config --global credential.helper 'cache --timeout=36000'`;
		if ( $me ) {

			#set vi by default
		}

		#Moo::Role repo
		`git clone https://github.com/m-macnair/Moo-Role.git $gitdir/Moo-Role`;
		push( @perllibs, "$gitdir/Moo-Role/lib/" );

	}

	BASH: {
		BASHPROFILE: {
			unless ( -e "$ENV{HOME}/.bash_profile" ) {
				`touch "$ENV{HOME}/.bash_profile"`;
				`chmod +x  "$ENV{HOME}/.bash_profile"`;
				`echo "#!/bin/bash" > "$ENV{HOME}/.bash_profile"`;
			}
			unless ( inprof( 'source ~/.bashrc' ) ) {
				`echo "source ~/.bashrc" > "$ENV{HOME}/.bash_profile"`;
			}
			`touch "$ENV{HOME}/.bashrc"` unless -e "$ENV{HOME}/.bashrc";
			my $in = inrc( 'Toolbox/WorkEnv/Bash/bash_source.sh' );
			unless ( $in ) {
				my $cmd = qq|echo "source $thisdir/Bash/bash_source.sh" >> "$ENV{HOME}/.bashrc"|;
				system( $cmd);
			}
		}
		BASHSOURCE: {

			#reset
			`echo 'export TOOLBOXDIR="$tbdir"' > $thisdir/Bash/bash_source.sh`;

			#append
			`echo 'export PATH="\$PATH:$thisdir/PathScripts"' >> $thisdir/Bash/bash_source.sh`;

			`cat $thisdir/Bash/bash_source_baseline.txt >> $thisdir/Bash/bash_source.sh`;

			push( @perllibs, "$tbdir/perl/lib/" );

			PERLLIBS: {
				my $perllibstr = join( ':', @perllibs );
				`echo 'export PERL5LIB="\$PERL5LIB:$perllibstr"' >> $thisdir/Bash/bash_source.sh`;
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
					"$thisdir/KDE/konsole"
				);
			}

		}

	}
}

sub inrc {
	my ( $value ) = @_;
	return `grep "$value" "$ENV{HOME}/.bashrc"`;
}

sub inprof {
	my ( $value ) = @_;
	return `grep "$value" "$ENV{HOME}/.bash_profile"`;
}

sub link_in_dir_unless_exists {
	my ( $source_file, $target_dir ) = @_;
	my ( $dev, $thisdir, $file ) = File::Spec->splitpath( $source_file );
	link_to_unless_exists( $source_file, "$target_dir/$file" );
}

sub link_to_unless_exists {
	my ( $source, $target ) = @_;

	unless ( -e $target ) {
		`ln -s $source $target`;
	}
}
