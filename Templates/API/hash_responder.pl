#!/usr/bin/perl
use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI';
with qw//;
has _something => (
	is      => 'rw',
	lazy    => 1,
	default => sub { return }
);

sub process {
	my ( $self ) = @_;
}
1;

package main;

main();

sub main {
	my $obj = Obj->new();
	$obj->get_config();

}
