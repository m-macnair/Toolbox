#!/usr/bin/perl
use strict;
use warnings;
use Toolbox::FileIO qw/slurptoref ofh/;
use Toolbox::FileSystem qw/safeduplicatepath safemvf /;
main( @ARGV );

sub main {

	my ( $path ) = @_;
	my $txt = slurptoref( $path );
	$$txt =~ s|\n\n[\n]+|\n\n|g;
	$$txt =~ s| [ ]+| |g;
	my $backup = safeduplicatepath( "$path.bak", {mute => 1} );
	safemvf( $path, $backup );
	my $ofh = ofh( $path );
	print $ofh $$txt;
	close( $ofh );

}
