# Script for detecting columns that should have indexes in mysql, and generating the sql statement if they don't
use strict;
use warnings;
use Toolbox::CombinedCLI;
use Toolbox::FileSystem;
use File::Slurp;
use DBI;
use Data::Dumper;
main();

sub main {
	my $c = Toolbox::CombinedCLI::get_config(
		[qw/
			columnfile
			dsnarray
		/],
		[qw/
		
		/]
	);
	Toolbox::FileSystem::checkfile( $c->{columnfile} );
	my @lines = File::Slurp::read_file( $c->{columnfile} );
	my @index_columns;
	for my $line ( @lines ) {
		if ( index( $line, '#' ) == 0 ) {
			next;
		}
		$line =~ s/[\W]//g;
		push( @index_columns, $line );
	}

	
	my $dbh = DBI->connect( @{$c->{dsnarray}} );
	

	# TODO skip tables
	my @stmnts;
	for my $table ( @{$dbh->selectcol_arrayref( "show tables" )} ) {
		
		my $index_map = {};

		my $describe_sth = $dbh->prepare( "describe $table" );
		$describe_sth->execute();
		my @found_columns;
		while ( my $columns_row = $describe_sth->fetchrow_hashref() ) {
			for my $trigger_column ( @index_columns ) {
				if ( $columns_row->{Field} eq $trigger_column ) {
					push( @found_columns, $trigger_column );
				}
			}
		}

		if ( @found_columns ) {
			my $found_indexes   = {};
			my $missing_indexes = {};
			my $index_sth       = $dbh->prepare( "show indexes from $table" );
			$index_sth->execute();
			while ( my $index_row = $index_sth->fetchrow_hashref() ) {
				for my $trigger_column ( @found_columns ) {
					next if $found_indexes->{$trigger_column};
					if ( $index_row->{Column_name} eq $trigger_column ) {
						if ( $index_row->{Seq_in_index} == 1 ) {
							$found_indexes->{$trigger_column} = 1;
						}
					}
				}

			}

			for my $trigger_column ( @found_columns ) {

				next if $found_indexes->{$trigger_column};
				push( @stmnts, "CREATE INDEX $trigger_column ON $table ($trigger_column);" );
			}
		}
	}

	for my $stmt ( @stmnts ) {
		print "$stmt$/";

	}
}

