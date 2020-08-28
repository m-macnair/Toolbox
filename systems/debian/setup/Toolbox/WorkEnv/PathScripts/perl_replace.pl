#!/usr/bin/perl
use strict;
use warnings;
use File::Find::Rule;
use Toolbox::FileSystem;
use File::Basename;
use Data::Dumper;
use Data::UUID;

# back up perl files with string 1 and replace with string 2 in the originals

main( @ARGV );

sub main {
	my ( $dir, $from, $to ) = @_;
	die "no dir"         unless $dir;
	die "no from string" unless $from;
	die "no to string"   unless $to;

	use File::Find::Rule;

	# find all the subdirectories of a given directory
	my @files     = File::Find::Rule->file->in( $dir );
	my $types     = {};
	my $ug        = Data::UUID->new;
	my $uuid      = lc( $ug->create_str() );
	my $cmdstring = qq#perl -pi -e "s|$from|$to|g"  #;

	for my $file ( @files ) {

		my ( $name, $path, $suffix ) = fileparse( $file, qr/\.[^.]*/ );

		next unless $name;  #suggests a hidden file;
		next unless $suffix;
		my $perlfile;
		for (
			qw/
			.pl
			.pm
			/
		  )
		{
			$perlfile = 1 if ( $suffix eq $_ );
		}
		if ( $perlfile ) {
			if ( `grep $from $file` ) {
				Toolbox::FileSystem::cpf( $file, "$file.bak-$uuid" );
				print `$cmdstring $file`;
			}
		}
	}

}
