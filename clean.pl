#!/usr/bin/perl
use strict;
use warnings;

=head1 Overview
	Removes all the junk/temp files created by kwrite & perltidy
=cut

main();

sub main {
	use File::Find;
	File::Find::find(
		{
			follow => 1,
			wanted => sub {
				if ( -d $File::Find::fullname ) {
					return;
				}

				#plain 'kill this file'
				for ( qw/.directory / ) {
					if ( $File::Find::fullname eq $_ ) {
						unlink( $File::Find::fullname );
					}
				}

				for (
					qw/
					.pm~
					.pl~
					.pl.bak
					.pm.bak
					.sh~
					.yml~
					.conf~
					.kate-swp
					.sql~
					.pm.tdy
					.pl.tdy
					.gz.gz
					/
				  )
				{

					if ( $File::Find::fullname =~ m($_$) ) {
						unlink( $File::Find::fullname );
					}
				}

			}

		},
		"./"
	);

}
