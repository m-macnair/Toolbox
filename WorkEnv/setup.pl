#!/usr/bin/perl

use strict;
use warnings;
use Cwd;
use File::Spec;
use File::Basename;
main();

sub main {

	my $thisfile = Cwd::abs_path( __FILE__ );
	my ( $dev, $thisdir, $file ) = File::Spec->splitpath( $thisfile );
	my $tbdir = Cwd::abs_path( dirname( $thisdir ) );
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
			`echo 'export PERL5LIB="\$PERL5LIB:$tbdir/perl/lib/"' >> $thisdir/Bash/bash_source.sh`;

			`cat $thisdir/Bash/bash_source_baseline.txt >> $thisdir/Bash/bash_source.sh`;

			# TODO moar
		}
	}

	PERL: {
		#connect perltidy if there isn't one already
		my $pt  = "$ENV{HOME}/.perltidyrc";
		my $tpt = Cwd::abs_path( "$thisdir/Perl/perltidyrc" );
		unless ( -e $pt ) {
			my $linked = eval { symlink( $tpt, $pt ); 1 };
			die "Failed to softlink $tpt as $pt : $!" unless $linked;
		}
	}

	GIT: {
		`git config --global credential.helper cache`;
		`git config --global credential.helper 'cache --timeout=36000'`;
		`git config --global core.editor "vi "`;
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

