use strict; # applies to all packages defined in the file
use Carp qw/cluck confess/;

package Toolbox::FileIO;

# ABSTRACT: Read and write files in various ways
our $VERSION = 'v1.0.3';

##~ DIGEST : 208a0497f37fec2a4e6c9065a3cb87c7

our $FILEHANDLES = {};

=head1 NAME
	~
=head1 VERSION & HISTORY
	0.0.1 - <date>
	0.0.0 - <date unless same as above>
=head1 SYNOPSIS
	Do FileIO things, functionally
=head2 TODO
=head1 EXPORT
=cut

use Exporter qw(import);
our @EXPORT_OK = qw(
  slurptoref
  slurp
  closefhs
  ofh
);

=head1 CODE
=head2 MAJOR SUBS
	Subs that use other subs to an abstract or specific end
=cut

=head2 MINOR SUBS
	Subs used by major subs, or other minor subs
=cut

sub slurptoref {
	my ( $path ) = @_;
	require Toolbox::FileSystem;
	Toolbox::FileSystem::checkfile( $path );
	require File::Slurp;
	my $return = File::Slurp::read_file( $path );
	return \$return; # return!
}

sub slurp {
	my ( $path ) = @_;
	return ${slurptoref( $path )};
}

sub ofh {
	my ( $path, $c ) = @_;
	$c ||= {};
	unless ( exists( $FILEHANDLES->{$path} ) ) {
		if ( $c->{fh} ) {
			$FILEHANDLES->{$path} = $c->{fh};
		} else {
			unless ( open( $FILEHANDLES->{$path}, $c->{openparams} || ">:encoding(UTF-8)", $path ) ) {
				confess( "Failed to open write file [$path] : $!" );
			}
		}
	}
	return $FILEHANDLES->{$path};
}

sub closefhs {
	my ( $paths ) = @_;

	#close all unless specific
	$paths ||= [ keys( %{$FILEHANDLES} ) ];

	for ( @{$paths} ) {
		close( $FILEHANDLES->{$_} ) or confess( "Failed to close file handle for [$_] : $!" );
		undef( $FILEHANDLES->{$_} );
	}

}

=head2 WRAPPERS
=head3 external_function
=cut

=head1 AUTHOR
	mmacnair, C<< <mmacnair at cpan.org> >>
=head1 BUGS
	TODO Bugs
=head1 SUPPORT
	TODO Support
=head1 ACKNOWLEDGEMENTS
	TODO
=head1 COPYRIGHT
	Copyright 2020 mmacnair.
=head1 LICENSE
	TODO
=cut

1;
