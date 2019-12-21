package Toolbox::FileVersion;
our $VERSION = '0.02';

##~ DIGEST : 921c89ff5cfb0e95d9dfbda9223e3bf1
use Moo;
use Toolbox::CombinedCLI;
use Toolbox::FileSystem;
use Digest::MD5;
use App::RewriteVersion;

sub file {

}

sub digest_source_file {
	my ( $self, $path ) = @_;

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

	my $return;
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
		my $md5 = Digest::MD5->new;
		$md5->add( $digestbuffer );
		$return->{digest} = $md5->hexdigest();

	} else {
		$return->{nodigest} = 1;
	}
	return $return; #return!

}

sub modify_version {
	my ( $self, $path, $vconf ) = @_
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
}

1;
