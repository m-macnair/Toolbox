use strict;
use warnings;
use Carp qw/croak confess cluck/;
use Toolbox::FileIO::CSV;
use Toolbox::FileSystem;

# ABSTRACT : turn a stack of method names into $self->method for when directly porting a functional to an oo module
main( @ARGV );

sub main {
	my ( $stackfile, $module ) = @_;
	if ( $module ) {
		$module .= '::';
	} else {
		$module = '';
	}
	Toolbox::FileSystem::checkfile( $stackfile );
	my @stack;
	Toolbox::FileIO::CSV::suboncsv(
		sub {
			my ( $row ) = @_;
			push( @stack, $row->[0] ) if $row->[0];
			return 1;
		},
		$stackfile
	);
	for my $method ( @stack ) {
		print "sub $method { shift; return $module$method(\@_); }$/";
	}
}

