#!/usr/bin/perl
# ABSTRACT:
use strict;
use warnings;
use JSON;
use File::Slurp;
use File::Find;
use Cwd;
use Carp qw/confess/;
main( @ARGV );

sub main {
	my ( $conf, $dir, $start_table ) = @_;
	my $db_conf = JSON::decode_json( File::Slurp::slurp( $conf ) );

	sub_on_files(
		sub {
			my ( $path ) = @_;

			print "$path$/";
			my $cstring = qq|mysql -A -h $db_conf->{host} -p -u $db_conf->{user} -p'$db_conf->{pass}' $db_conf->{db} < $path \;|;

			print `$cstring`;
			return 1;
		},
		$dir
	);

}

sub sub_on_files {
	my ( $sub, $dir ) = @_;
	confess( "Directory not provided" )                                 unless defined( $dir );
	confess( "First parameter to subonfiles was not a code reference" ) unless ref( $sub ) eq 'CODE';
	confess( "Directory [$dir] not usable" )                            unless -d $dir;

	File::Find::find(
		{
			wanted => sub {
				return unless -f $File::Find::name;

				#Because File::Find doesn't support early termination natively, but is also the only Find facility in core
				goto FileSystem_sub_on_files_end unless &$sub( Cwd::abs_path( $File::Find::name ) );
			},
			no_chdir => 1,
		},
		$dir

	);

	FileSystem_sub_on_files_end:

	return 1;
}
