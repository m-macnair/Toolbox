use strict;
use warnings;
use Toolbox::Class::FileHashDB::Mk77;
main(@ARGV);

sub main {

	my ($path) = @_;
	my $fhdb = Toolbox::Class::FileHashDB::Mk77->new();
	$fhdb->criticalpath3($path);
	print "It is done. Move on!$/";

}
