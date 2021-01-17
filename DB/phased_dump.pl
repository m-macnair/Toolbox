#!/usr/bin/perl
use strict;
use warnings;

package Object;
use Carp qw/ cluck confess /;
use Moo;
use Data::Dumper;
use POSIX;
ACCESSORS: {
}

#dbh overwrites DB's version
with qw/
  MyDBDelta::Core
  /;

sub criticalpath {

	my ( $self ) = @_;
	for my $table ( @{$self->tablestack()} ) {
		$self->processtable( $table );
	}

}

sub processtable {

	my ( $self, $table ) = @_;

}
1;

package main;
use Carp qw/ cluck confess /;
use Toolbox::CombinedCLI;
use DBI;
use Data::Dumper;
main();

sub main {

	my $obj = Object->new();
	$obj->get_config(
		[
			qw/
			  user
			  db
			  host
			  driver
			  id
			  /
		],
		[
			qw/
			  /
		]
	);
	$obj->criticalpath();

}
