use strict;
use warnings;
main();
sub main {

	require Cwd;
	my $thisfile = Cwd::abs_path( __FILE__ );
	require File::Spec;
	my ( $dev, $thisdir, $file ) = File::Spec->splitpath( $thisfile );

	BASH: {
		my $in = inrc( 'Toolbox/WorkEnv/bash_source.sh' );
		
		unless ($in ) {
			
			my $cmd = qq|echo "source $thisdir/bash_source.sh" >> "$ENV{HOME}/.bashrc"|;

			system($cmd);
		}

		# Set up some environment variables
		BASHSOURCE: {
			`echo 'export PATH="\$PATH:$thisdir/Path"' > $thisdir/bash_source.sh`;

			# TODO moar
			my $cat = "$thisdir/bash_source_baseline.txt >> $thisdir/bash_source.sh";
			`cat $cat `;
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
	return ` grep "$value" "$ENV{HOME}/.bashrc"`;
}

