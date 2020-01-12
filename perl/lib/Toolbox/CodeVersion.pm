package Toolbox::CodeVersion;

# ABSTRACT : Modify version numbers for perl files based on digests of the file after the version string
our $VERSION = '0.04';

##~ DIGEST : ab8af56c58b388608c3b1a23fedc241a
use Moo;
use Toolbox::CombinedCLI;
use Toolbox::FileSystem;
use Digest::MD5;
use App::RewriteVersion;

sub process_file {
	my ( $self, $path, $conf ) = @_;
	my $digest_result = $self->digest_source_file( $path );
	print $digest_result->{output} unless $conf->{quiet};

	if ( $digest_result->{new_digest} || $conf->{set} ) {

		#for when just the digest needs doing
		return if $conf->{skipversion};
		my $modify_result = $self->modify_version( $path, $conf );
		print $modify_result->{output} unless $conf->{quiet};
	}
	print $/ unless $conf->{quiet};
}

sub digest_source_file {
	my ( $self, $path ) = @_;
	my $return = {};
	$return->{output} .= "$/Working on $path$/";
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
			$return->{output} .= "\tCurrent Digest : $od$/";
		} else {
			splice( @writebuffer, $versionline + 1, 0, ( $/ ) );
			$digestline = $versionline + 2;
		}
		$return->{output} .= "\tDigest Position : $digestline$/";
		$return->{output} .= "\tVersion Position : $versionline$/";
		my $digestbuffer = join( '', splice( @writebuffer, $digestline ) );
		my $md5 = Digest::MD5->new;
		$md5->add( $digestbuffer );
		my $digest = $md5->hexdigest();
		if ( $od ) {

			if ( $od eq $digest ) {
				$return->{nochange} = 1;
			} else {
				$return->{output} .= "\tNew digest : $digest$/";
				$return->{new_digest} = 1;
				$return->{changed}    = 1;
			}

		} else {
			$return->{new_digest} = 1;
			$return->{no_digest}  = 1;
		}
		if ( $return->{new_digest} ) {

			#remove the old one
			push( @writebuffer, "$digestident$digest$/" );
			my $work = join( '', @writebuffer ) . $digestbuffer;

			open( my $ofh, '>', $path ) or die $!;
			print $ofh $work;
			close( $ofh );
			$return->{new_digest} = 1;

		}
	}
	return $return; #return!

}

sub modify_version {
	my ( $self, $path, $conf ) = @_;
	my $return = {};
	my $app    = App::RewriteVersion->new();
	my $cv     = $app->version_from( Toolbox::FileSystem::abspath( $path ) );

	if ( $cv ) {
		`cp "$path" "$path.bak"`;
		my $new_version;
		if ( $conf->{set} ) {

			$new_version = $conf->{set};
			$return->{output} .= "\tExplicit version : $new_version";
		} elsif ( $conf->{increment} ) {
			$new_version = $cv + $conf->{increment};
			$return->{output} .= "\tVersion Increment of $conf->{increment} to $new_version";
		} else {
			$new_version = $cv + 0.01;
			$return->{output} .= "\tVersion AutoIncrement to $new_version";
		}

		$app->rewrite_version( $path, $new_version );

	} else {
		$return->{output} .= "$path does not have a usable version identifier - may not be quoted correctly?";
	}

	return $return; #return!
}

1;
