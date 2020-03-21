package Toolbox::Class::CodeVersion;

# ABSTRACT : Modify version numbers for perl files based on digests of the file after the version string
our $VERSION = 'v1.0.2';

##~ DIGEST : 33548dd4a1d2550cef88f189513bfdcb
use Moo;

ACCESSORS: {

	has rewriter => is => 'rw',
	  lazy       => 1,
	  default    => sub {
		require App::RewriteVersion;

		#no ()!!
		return App::RewriteVersion->new;
	  };

	has mute  => is => 'rw',
	  lazy    => 1,
	  default => sub {
		1;
	  };
}
use Toolbox::CombinedCLI;
use Toolbox::FileSystem;
use Digest::MD5;

=head2 MAJOR
=cut

sub process_file {
	my ( $self, $path, $conf ) = @_;
	die "Obsolete";
	my $digest_result = $self->digest_source_file( $path );
	print $digest_result->{output} unless $self->mute();

	if ( $digest_result->{new_digest} || $conf->{set} ) {

		#for when just the digest needs doing
		return if $conf->{skipversion};
		my $modify_result = $self->modify_version( $path, $conf );
		print $modify_result->{output} unless $self->mute();
	}
	print $/ unless $self->mute();
}

sub mmp {
	my ( $self, $path, $conf ) = @_;
	my $digest_result = $self->digest_source_file( $path );
	print $digest_result->{output} unless $self->mute();

	if ( $digest_result->{new_digest} || $conf->{force} ) {

		#for when just the digest needs doing
		return if $conf->{skipversion};
		my $modify_result = $self->_mmmp( $path, $conf );
		print $modify_result->{output}, $/ unless $self->mute();
	}

}

sub detectversiontype {
	my ( $self, $path, $conf ) = @_;

	my $currentversion = $self->rewriter->version_from( Toolbox::FileSystem::abspath( $path ) );

	return scalar( split( '\.', $currentversion ) );

}

=head2 MINOR
=cut

sub _mmmp {
	my ( $self, $path, $conf ) = @_;
	my $return = {};

	my $currentversion = $self->rewriter->version_from( Toolbox::FileSystem::abspath( $path ) );

	if ( $currentversion ) {
		`cp "$path" "$path.bak"`;
		my $newversion;
		if ( $conf->{set} ) {

			$newversion = $conf->{set};
			$return->{output} .= "\tExplicit version : $newversion";
		} else {
			$newversion = $self->rewriter->bump_version( $currentversion );
			$return->{output} = "\tNew version : $newversion";
		}

		#actually do something
		$self->rewriter->rewrite_version( $path, $newversion );
	} else {
		$return->{output} .= "$path does not have a usable version identifier - may not be quoted correctly?";
	}

	return $return; #return!
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
		my $md5          = Digest::MD5->new;
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

	my $currentversion = $self->rewriter->version_from( Toolbox::FileSystem::abspath( $path ) );

	if ( $currentversion ) {
		`cp "$path" "$path.bak"`;
		my $newversion;
		if ( $conf->{set} ) {

			$newversion = $conf->{set};
			$return->{output} .= "\tExplicit version : $newversion";
		} elsif ( $conf->{increment} ) {
			$newversion = $currentversion + $conf->{increment};
			$return->{output} .= "\tVersion Increment of $conf->{increment} to $newversion";
		} else {
			$newversion = $currentversion + 0.01;
			$return->{output} .= "\tVersion AutoIncrement to $newversion";
		}

		$self->rewriter->rewrite_version( $path, $newversion );

	} else {
		$return->{output} .= "$path does not have a usable version identifier - may not be quoted correctly?";
	}

	return $return; #return!
}

1;
