#!/usr/bin/perl
use strict;
use warnings;

package Object;
use Carp qw/ cluck confess /;
use Moo;
with qw//;
has _something => (
	is      => 'rw',
	lazy    => 1,
	default => sub { return }
);
1;

package main;
use Carp qw/ cluck confess /;
use Toolbox::CombinedCLI;
main();

sub main {
	my $clv = Toolbox::CombinedCLI::get_config(
		[
			qw/

			/
		]
	);
	my $obj = Object->new();
}
