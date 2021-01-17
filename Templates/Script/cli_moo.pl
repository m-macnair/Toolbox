#!/usr/bin/perl
# ABSTRACT: 
our $VERSION = 'v0.0.0';


use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI'; #provides  CLI, FileSystem, Common
with qw/
  Moo::GenericRole::FileSystem
  Moo::GenericRole::FileIO
  Moo::GenericRole::FileIO::CSV

  Moo::GenericRole::JSON

  Moo::GenericRole::DB
  Moo::GenericRole::DB::Abstract
  Moo::GenericRole::DB::MariaMysql
  Moo::GenericRole::DB::SQLite

  Moo::GenericRole::TimeHiRes
  Moo::GenericRole::PID
  Moo::GenericRole::UUID

  Moo::GenericRole::Web
  Moo::GenericRole::UserAgent
  Moo::GenericRole::Dispatch

  /;
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
	my $self = Obj->new();
	$self->get_config(
		[qw//],
		[
			qw/
			  in_file
			  out_file
			  db_def_file

			  /
		],
		{
			required => {},
			optional => {}
		}
	);
	$self->process();

}
