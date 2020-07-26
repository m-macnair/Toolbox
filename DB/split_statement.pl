# Script for distributing the output of detect_missing_keys.pl to individual table specific files
use strict;
use warnings;
use Toolbox::CombinedCLI;
use Toolbox::FileSystem;
use File::Slurp;
use DBI;
use Data::Dumper;
main();

sub main {
	my $clv = Toolbox::CombinedCLI::get_config(
		[
			qw/
			  path
			  /
		],
		[
			qw/
			  odir
			  /
		]
	);
	my $odir   = $clv->{odir} || Toolbox::FileSystem::tempdir();
	my @lines  = File::Slurp::read_file( $clv->{path} );
	my $tables = {};
	for my $line ( @lines ) {
		my ( $tablename ) = ( $line =~ m/ON ([^\(].*) \(/ );
		push( @{$tables->{$tablename}}, $line );
	}
	for my $table ( keys( %{$tables} ) ) {
		open( my $ofh, '>', "$odir/$table.sql" );
		print $ofh join( '', @{$tables->{$table}} );
		close( $ofh );
	}
}
