#!/usr/bin/env perl
#ABSTRACT: given DSN for a database, export each table definition to its own file
#Made with ChatGPT
use strict;
use warnings;
our $VERSION = 'v1.0.0';

##~ DIGEST : 0704f08e2281078cab0d1df806a9c83c
use DBI;
use File::Path qw(make_path);
use File::Spec;

# ------------------------------------------------------------
# Usage:
#
#   perl export_schema.pl \
#       --dsn 'DBI:mysql:database=test;host=localhost' \
#       --user root \
#       --pass secret \
#       --out schema
#
# Supports:
#   - MySQL / MariaDB
#   - PostgreSQL
#   - SQLite
#
# Each table definition is written to:
#   <out>/<table_name>.sql
# ------------------------------------------------------------

use Getopt::Long qw(GetOptions);

my %args;

GetOptions(
	'dsn=s'  => \$args{dsn},
	'user=s' => \$args{user},
	'pass=s' => \$args{pass},
	'out=s'  => \$args{out},
	'full=s' => \$args{full},
) or die "Invalid arguments\n";

print "DSN  = $args{dsn}\n";
print "USER = $args{user}\n" if defined $args{user};
print "OUT  = $args{out}\n"  if defined $args{out};

die "Missing --dsn\n" unless $args{dsn};

die "Missing --dsn\n" unless $args{dsn};

my $out_dir = $args{out} || 'schema';

make_path( $out_dir ) unless -d $out_dir;

my $dbh = DBI->connect(
	$args{dsn},
	$args{user} // '',
	$args{pass} // '',
	{
		RaiseError => 1,
		PrintError => 0,
		AutoCommit => 1,
	}
) or die "Connection failed: $DBI::errstr\n";

my $driver = $dbh->{Driver}->{Name};

print "Connected using driver: $driver\n";

my @tables = get_tables( $dbh );

for my $table ( @tables ) {
	my $ddl = get_table_ddl( $dbh, $driver, $table, \%args );

	my $file = File::Spec->catfile( $out_dir, "$table.sql" );
	output_ddl( $file, $ddl, $table );

}

$dbh->disconnect;

sub output_ddl {
	my ( $file, $ddl, $table ) = @_;
	my $final = $ddl;
	$final .= ";\n";

	my $existing = '';
	if ( -e $file ) {
		open my $fh, '<', $file or die "Cannot read $file: $!";
		local $/;
		$existing = <$fh>;
		close $fh;
	}

	if ( -e $file && normalize( $existing ) eq normalize( $final ) ) {
		print "Unchanged: $table (skipping write)\n";
		return;
	}

	open my $fh, '>', $file
	  or die "Cannot write $file: $!";

	print {$fh} $final;

	close $fh;

	print "Exported: $table -> $file\n";

}

# normalize comparison to avoid false diffs
sub normalize {
	my $s = shift;
	$s =~ s/\r\n/\n/g;
	$s =~ s/\s+\n/\n/g;
	$s =~ s/\n+\z/\n/;
	return $s;
}

# ------------------------------------------------------------
# Get table list
# ------------------------------------------------------------
sub get_tables {
	my ( $dbh ) = @_;

	my @tables;

	my $sth = $dbh->table_info( undef, undef, undef, 'TABLE' );

	while ( my $row = $sth->fetchrow_hashref ) {
		push @tables, $row->{TABLE_NAME};
	}

	return sort @tables;
}

# ------------------------------------------------------------
# Export DDL per DB engine
# ------------------------------------------------------------
sub get_table_ddl {
	my ( $dbh, $driver, $table, $args ) = @_;
	%args = %$args;
	if ( $driver eq 'mysql' ) {
		my $sth = $dbh->prepare( "SHOW CREATE TABLE `$table`" );
		$sth->execute();

		my ( $name, $ddl );
		if ( $args{full} ) {
			( $name, $ddl ) = $sth->fetchrow_array;
		} else {
			( $name, $ddl ) = $sth->fetchrow_array;

			# Extract only CREATE TABLE (...) portion
			if ( $ddl =~ /(CREATE TABLE.*\))/s ) {
				$ddl = $1;
			}
		}
		return $ddl;

	} elsif ( $driver eq 'Pg' ) {
		return pg_generate_table_ddl( $dbh, $table );

	} elsif ( $driver eq 'SQLite' ) {
		my $sth = $dbh->prepare(
			q{
            SELECT sql
            FROM sqlite_master
            WHERE type = 'table'
              AND name = ?
        }
		);

		$sth->execute( $table );

		my ( $ddl ) = $sth->fetchrow_array;

		return $ddl;

	} else {
		die "Unsupported driver: $driver\n";
	}
}

# ------------------------------------------------------------
# PostgreSQL DDL generator
# Basic CREATE TABLE reconstruction
# ------------------------------------------------------------
sub pg_generate_table_ddl {
	my ( $dbh, $table ) = @_;

	my $sql = q{
        SELECT
            column_name,
            data_type,
            is_nullable,
            column_default,
            character_maximum_length
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = ?
        ORDER BY ordinal_position
    };

	my $sth = $dbh->prepare( $sql );
	$sth->execute( $table );

	my @cols;

	while ( my $row = $sth->fetchrow_hashref ) {
		my $type = $row->{data_type};

		if ( defined $row->{character_maximum_length}
			&& $type =~ /char/i )
		{
			$type .= "($row->{character_maximum_length})";
		}

		my $col = qq{    "$row->{column_name}" $type};

		if ( defined $row->{column_default} ) {
			$col .= " DEFAULT $row->{column_default}";
		}

		if ( $row->{is_nullable} eq 'NO' ) {
			$col .= " NOT NULL";
		}

		push @cols, $col;
	}

	return sprintf( "CREATE TABLE \"%s\" (\n%s\n)", $table, join( ",\n", @cols ) );
}

# ------------------------------------------------------------
# Simple CLI parser
# ------------------------------------------------------------

