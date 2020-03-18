#!/usr/bin/perl
use strict;
use warnings;
use File::Find::Rule;
use Toolbox::FileSystem;
use File::Basename;
use Data::Dumper;
use Data::UUID;

main( @ARGV );

sub main {
	my ( $dir, $piestring ) = @_;

	use File::Find::Rule;

	# find all the subdirectories of a given directory
	my @files     = File::Find::Rule->file->maxdepth( 1 )->in( $dir );
	my $types     = {};
	my $ug        = Data::UUID->new;
	my $uuid      = lc( $ug->create_str() );
	my $cmdstring = qq#perl -pi -e "$piestring"  #;

	for my $file ( @files ) {

		my ( $name, $path, $suffix ) = fileparse( $file, qr/\.[^.]*/ );

		next unless $name;  #suggests a hidden file;
		next unless $suffix;
		my $yes;
		for (
			qw/
			.pl
			.pm
			/
		  )
		{
			$yes = 1 if ( $suffix eq $_ );
		}
		if ( $yes ) {
			Toolbox::FileSystem::cpf( $file, "$file.bak-$uuid" );
			print `$cmdstring $file`;
		}
	}

}
