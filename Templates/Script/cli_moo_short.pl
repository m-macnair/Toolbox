#!/usr/bin/perl
# ABSTRACT:
our $VERSION = 'v0.0.3';

##~ DIGEST : ef0b52c1baf76d870d93db7a987067ac

use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI'; #provides  CLI, FileSystem, Common
with qw/

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

sub process {
	my ( $self ) = @_;
}
1;

package main;

main( @ARGV );

sub main {
	my $self = Obj->new();
	$self->process( @_ );

}
