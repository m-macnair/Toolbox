#!/usr/bin/perl
use strict;
use warnings;
use Carp qw/croak confess cluck/;
use DBI;
use Data::Dumper;
use JSON;
use Try::Tiny;
use Digest::MD5;

main( @ARGV );

sub main {
	my ( $C_file ) = @_;
	my $C          = jsonloadfile( $C_file );
	my $dsn        = "dbi:mysql:$C->{db}";
	my $dumpprefix = $C->{dumpprefix};
	DUMPPREFIX: {
		$dumpprefix ||= ' --skip-comments ';
	}

	my $rootdir = $C->{path} || './';
	if ( $C->{host} ) {
		$dsn        .= ";host=$C->{host}";
		$dumpprefix .= " -h $C->{host} ";
	}

	if ( $C->{port} ) {
		$dsn        .= ";port=$C->{port}";
		$dumpprefix .= " -P $C->{port} ";
	}

	my $dbh = DBI->connect( $dsn, $C->{user}, $C->{pass} );
	my $port       = $C->{port}       || 3306;
	my @exceptions = $C->{exceptions} || [];
	my $sth        = $dbh->prepare( "show tables" );
	$sth->execute();
	my @tables;
	while ( my $row = $sth->fetchrow_arrayref() ) {

		unless ( $row->[0] =~ @exceptions ) {
			push( @tables, $row->[0] );
		}
	}
	for my $table ( @tables ) {
		my $table_dir = "$rootdir/$table/";
		unless ( -e $table_dir ) {
			mkpath( $table_dir );
		}

		unless ( $C->{skip_schema} ) {
			my $newfile = abspath( "$table_dir/schema_[" . time_string() . '].sql' );
			my $cmd     = "mysqldump $dumpprefix --single-transaction --no-data -u $C->{user} -p$C->{pass} $C->{db} $table";
			print ` $cmd > $newfile`;
			compare_new( $table_dir, $newfile, 'schema' );

		}

		DATA: {
			my $newfile = abspath( "$table_dir/data_[" . time_string() . '].sql' );
			my $cmd     = "mysqldump $dumpprefix --single-transaction --no-create-info -u $C->{user} -p$C->{pass} $C->{db} $table";
			print ` $cmd > $newfile`;
			compare_new( $table_dir, $newfile, 'data' );
		}

	}
}

sub time_string {
	use POSIX qw(strftime);
	my $now = time();
	return strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime( $now ) );
}

sub digest_file {
	my ( $path ) = @_;
	open( my $fh, '<:raw', $path )
	  or die "failed to open digest file [$path] : $!";
	my $ctx = Digest::MD5->new;
	$ctx->addfile( $fh );
	close( $fh );
	return $ctx->hexdigest();
}

sub compare_new {
	my ( $dir, $newfile, $string ) = @_;
	my $newdigest = digest_file( $newfile );
	subonfiles(
		sub {
			my ( $oldfile ) = @_;

			#lul
			return if $newfile eq $oldfile;
			warn index( $oldfile, $string );
			if ( index( $oldfile, $string ) != -1 ) {
				my $olddigest = digest_file( $oldfile );
				print "Checking $oldfile.$olddigest against $newfile.$newdigest $/";

				#duplicate file - delete the newly generated one
				if ( $olddigest eq $newdigest ) {
					print "$oldfile is identical to new $string$/";
					unlink( $newfile );
					return 1;
				}
			}
		},
		$dir
	);
}

=head3 Toolbox:: dupes
	torn from my Toolbox namespace on account of the full install is low ROI in some cases
=cut

sub jsonloadfile {

	my ( $path ) = @_;
	my $buffer = '';

	open( my $fh, '<:raw', $path )
	  or die "failed to open file [$path] : $!";

	# :|
	while ( my $line = <$fh> ) {
		chomp( $line );
		$buffer .= $line;
	}
	close( $fh );
	JSON::decode_json( $buffer );

}

sub mkpath {
	my ( $path ) = @_;
	confess "Path missing" unless $path;
	return $path if -d $path;
	require File::Path;
	my $errors;
	File::Path::make_path( $path, {error => \$errors} );
	if ( $errors && @{$errors} ) {
		my $errstr;
		for ( @{$errors} ) {
			$errstr .= $_ . $/;
		}
		confess( "[$path] creation failed : [$/$errstr]$/" );
	}
	return $path;

}

sub subonfiles {
	my ( $sub, $dir ) = @_;
	require File::Find::Rule;
	confess( "First parameter to subonfiles was not a code reference" )
	  unless ref( $sub ) eq 'CODE';

	my @files = File::Find::Rule->file()->in( $dir );
	my $stop;
	for ( @files ) {
		$stop = &$sub( abspath( $_ ) );
		last if $stop;
	}
}

sub abspath {

	my ( $path ) = @_;
	my $return;
	if ( -e $path ) {
		require Cwd;
		$return = Cwd::abs_path( $path );
		if ( -d $return ) {
			$return .= '/';
		}
	} else {
		require File::Spec;
		$return = File::Spec->rel2abs( $path );
	}
	return $return; #return!

}

