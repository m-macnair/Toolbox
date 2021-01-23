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
		[
			qw/
			  columnfile
			  dsnarray
			  /
		],
		[
			qw/
			  /
		]
	);
	Toolbox::FileSystem::checkfile( $c->{columnfile} );
	my @lines = File::Slurp::read_file( $c->{columnfile} );
	my @index_columns;
	for my $line ( @lines ) {
		if ( index( $line, '#' ) == 0 ) {
			next;
		}
		next unless $line;
		$line =~ s/[\W]//g;
		my @elements = split( ',', $line );
		next unless ( @elements );
		my $def = {
			column => shift( @elements ),
			types  => [],
			tables => [],
		};
		for my $element ( @elements ) {
			if ( index( $element, '/' ) == 0 ) {
				push( @{$def->{types}}, substr( $element, 1 ) );
			} else {
				push( @{$def->{tables}}, $element );
			}
		}
		push( @index_columns, $def );
	}
	my $dbh       = DBI->connect( @{$c->{dsnarray}} );
	my $forbidden = [
		qw/
		  blob
		  text
		  /
	];

	# TODO skip tables
	my @stmnts;
	for my $table ( @{$dbh->selectcol_arrayref( "show tables" )} ) {
		my $index_map    = {};
		my $describe_sth = $dbh->prepare( "describe $table" );
		$describe_sth->execute();
		my @found_columns;
		while ( my $columns_row = $describe_sth->fetchrow_hashref() ) {
			next unless $columns_row->{Field}; #this apparently happens
			THISCOL: {
				#generally forbidden indices
				for my $badtype ( @{$forbidden} ) {
					if ( index( lc( $columns_row->{Type} ), $badtype ) != -1 ) {

						# 						warn "Skipping $table.$columns_row->{Field} as it is a [$badtype]";
						last THISCOL;
					}
				}
				for my $columndef ( @index_columns ) {

					if ( $columns_row->{Field} eq $columndef->{column} ) {
						for my $specificbadtype ( @{$columndef->{types}} ) {
							if ( index( lc( $columns_row->{Type} ), $specificbadtype ) != -1 ) {

								# 								warn "Skipping $table.$columns_row->{Field} as it is an explicitely forbidden [$specificbadtype]";
								last THISCOL;
							}
						}
						for my $specificbadtable ( @{$columndef->{tables}} ) {
							if ( $specificbadtable eq $table ) {

								# 								warn "Skipping $table.$columns_row->{Field} as it is in explicitely forbidden table [$specificbadtable]";
								last THISCOL;
							}
						}
						push( @found_columns, $columndef );
					}
				}
			}
		}
		if ( @found_columns ) {
			my $existingindex   = {};
			my $missing_indexes = {};
			my $index_sth       = $dbh->prepare( "show indexes from $table" );
			$index_sth->execute();
			while ( my $index_row = $index_sth->fetchrow_hashref() ) {

				for my $columndef ( @found_columns ) {

					#inefficient loop
					next if $existingindex->{$columndef->{column}};

					if ( $index_row->{Column_name} eq $columndef->{column} ) {

						# 						print "Triggered on  $index_row->{Column_name} eq $columndef->{column} with sequence : $index_row->{Seq_in_index} $/";
						if ( $index_row->{Seq_in_index} == 1 ) {

							$existingindex->{$columndef->{column}} = 1;
						}
					}
				}
			}
			for my $columndef ( @found_columns ) {
				next if $existingindex->{$columndef->{column}};
				push( @stmnts, "CREATE INDEX `$columndef->{column}\_auto_idx` ON $table (`$columndef->{column}`);" );
			}
		}
	}
	for my $stmt ( @stmnts ) {
		print "$stmt$/";
	}

}

sub skiptype {

}
