use strict;
use warnings;

package Toolbox::JSON;
require Exporter;
use Carp qw/confess croak/;
our @ISA = qw(Exporter);

our @EXPORT = qw/
  jsonloadfile
  json_general_load
  /;
use JSON;

sub jsonloadfile {

	my ( $path ) = @_;
	my $buffer;
	open( my $fh, '<', $path ) or die "failed to open file [$path] : $!";
	while ( <$fh> ) {
		$buffer .= $_;
	}
	close( $fh );
	JSON::decode_json( $buffer );

}

=head3 json_general_load
	load one or a bunch of jsons into a hash for to do something with later
=cut

sub json_general_load {
	my ( $path ) = @_;
	confess( "non-existent path [$path]" ) unless ( -e $path );
	my $return;
	if ( -f $path ) {
		$return->{$path} = jsonloadfile( $path );
	} elsif ( -d $path ) {
		require File::Find::Rule;
		my @files = File::Find::Rule->file()->name( '*.json' )->in( $path );
		for my $file ( @files ) {
			$return->{$file} = jsonloadfile( $file );
		}
	}
	return $return; # return
}

1;