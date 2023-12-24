#!/usr/bin/perl
# ABSTRACT: replace snake_case subroutine names and calls with $work compatibles
use strict;
use warnings;
use Data::Dumper;
use File::Find::Rule;
use File::Copy;
main( @ARGV );

sub main {

	my ( $dir ) = @_;
	die "No directory provided!"     unless $dir;
	die "Directory [$dir] not found" unless -d $dir;
	my @pmlist = File::Find::Rule->file()->name( "*.pm" )->in( $dir );
	my $submap = {};
	for my $path ( @pmlist ) {
		open( my $fh, '<:raw', $path )
		  or die "failed to open file [$path] : $!";

		# :|
		while ( my $line = <$fh> ) {
			next unless index( $line, '_' ) != -1;
			next unless index( $line, 'sub ' ) == 0;
			my $prefix = '';
			if ( index( $line, 'sub _' ) == 0 ) {
				$prefix = '_';
			}
			my ( $subname ) = ( $line =~ m/sub (.*) \{/ );
			die "Sub missing ?!" unless $subname;
			my $newsubname = $subname;
			$newsubname =~ s/_//g;
			$newsubname = "$prefix$newsubname";
			print "$subname -> $newsubname$/";
			$submap->{$subname} = $newsubname;
		}
		close( $fh );
	}
	warn Dumper( $submap );

	# 	sleep 10 + scalar(keys(%{$submap}));
	my @pllist = File::Find::Rule->file()->name( "*.pl" )->in( $dir );
	for my $path ( @pmlist, @pllist ) {
		my $backup = "$path.prereplace_" . time;
		File::Copy::mv( $path, $backup ) or die "$!";
		open( my $ifh, '<:raw', $backup )
		  or die "failed to open copied input file [$backup] : $!";
		open( my $ofh, '>:raw', $path )
		  or die "failed to open output file [$path] : $!";
		my $lc;
		while ( my $line = <$ifh> ) {
			$lc++;
			for my $bs ( keys( %{$submap} ) ) {
				my $gs = $submap->{$bs};
				if ( index( $line, 'sub' ) == 0 ) {
					$line =~ s/$bs/$gs/g;
				} else {
					$line =~ s/$bs\(/$gs(/g;
				}
				if ( $line =~ m/(!?$)$bs(?!\()/ ) {
					warn "Potentially missed sub call of $bs -> $gs \n\ton line $lc of $path : $line";
				}
			}
			print $ofh $line;
		}
		close( $ifh );
		close( $ofh );
	}

}
