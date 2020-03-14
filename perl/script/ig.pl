use strict;
use warnings;
use Toolbox::CombinedCLI;

package IGAPI;

package main;

main();

sub main {
	my $conf = Toolbox::CombinedCLI::get_config(
		[
			qw/
			  user
			  pass
			  url
			  /
		]
	);

}
