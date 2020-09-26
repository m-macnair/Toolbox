#!/usr/bin/perl
use strict;
use warnings;
use Toolbox::CombinedCLI;
use Toolbox::FileSystem;
use Digest::MD5;
use App::RewriteVersion;
main( @ARGV );

=head1 ABSTRACT

	For a .pm file
		Detect presence of digest
		after 'VERSION' definition, construct a digest
		compare digests
		if no match; create a new digest and bump module version number

=cut

sub main {

	my ( $path ) = @_;
	print "$/Working on $path$/";
	Toolbox::FileSystem::checkfile( $path );
	open( my $fh, '<', $path ) or die "$!";
	my $versionline;
	my $digestline = '';
	my @writebuffer;
	my $dodigest = 0;
	my $founddigest;
	my $digestident = '##~ DIGEST : ';

	while ( <$fh> ) {
		push( @writebuffer, $_ );
		if ( !$versionline && ( index( $_, 'our $VERSION' ) == 0 ) ) {
			$versionline = scalar( @writebuffer ) - 1;
			next;
		}
		if ( !$digestline && ( index( $_, $digestident ) == 0 ) ) {
			$digestline = scalar( @writebuffer ) - 1;
			next;
		}
	}
	close( $fh );
	if ( $versionline ) {
		my $od;
		if ( $digestline ) {
			my $line = splice( @writebuffer, $digestline, 1 );
			( undef, $od ) = split( $digestident, $line );
			chomp( $od );
			print "\tcurrentdigest : $od$/";
		} else {
			splice( @writebuffer, $versionline + 1, 0, ( $/ ) );
			$digestline = $versionline + 2;
		}
		print "\tdigest position : $digestline$/";
		print "\tversion position : $versionline$/";
		my $digestbuffer = join( '', splice( @writebuffer, $digestline ) );
		my $md5          = Digest::MD5->new;
		$md5->add( $digestbuffer );
		my $digest = $md5->hexdigest();
		unless ( $od && ( $od eq $digest ) ) {

			#remove the old one
			push( @writebuffer, "$digestident$digest$/" );
			my $work = join( '', @writebuffer ) . $digestbuffer;
			my $app  = App::RewriteVersion->new();
			my $cv   = $app->version_from( Toolbox::FileSystem::abspath( $path ) );
			unless ( $cv ) {
				print "$path does not have a usable version identifier - may not be quoted correctly?";
			}
			`cp "$path" "$path.bak"`;
			open( my $ofh, '>', $path ) or die $!;
			print $ofh $work;
			close( $ofh );
			$cv += 0.01;
			print "\tnew version : $cv";
			$app->rewrite_version( $path, $cv );
		}
	} else {
		warn "$path does not have a version string";
	}

}
