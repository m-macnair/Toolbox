#!/usr/bin/perl
use strict;
use warnings;
use Toolbox::CodeVersion;
use Toolbox::CombinedCLI;

main( );

=head1 ABSTRACT

	On a file
		Detect presence of digest
		after 'VERSION' definition, construct a digest
		compare digests
		if no match; create a new digest and bump module version number according to params

=cut

sub main {
	my $conf = Toolbox::CombinedCLI::array_config([qw/ path/],[qw/increment set /]);

	my $cv= Toolbox::CodeVersion->new();
	$cv->process_file($conf->{path}, $conf);

}
