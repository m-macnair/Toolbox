#!/usr/bin/perl
# ABSTRACT: given a text file and some non-default values, execute each line in the text file in its own screen in parallel
our $VERSION = 'v0.0.7';
##~ DIGEST : 4a874dcf920deb730ede8ba4d21cd391
use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI'; #provides  CLI, FileSystem, Common
with qw/
  Moo::GenericRole::FileSystem
  Moo::GenericRole::FileIO
  Moo::GenericRole::FileIO::CSV
  Moo::GenericRole::Screen
  /;
has _something => (
	is      => 'rw',
	lazy    => 1,
	default => sub { return }
);

sub process {

	my ( $self ) = @_;
	$self->check_file( $self->cfg->{in_file} );
	open( my $ifh, '<', $self->cfg->{in_file} ) or die $!;
	my $value_sub = sub {
		return <$ifh>;
	};
	my $counter          = 0;
	my $screen_name_root = $self->cfg->{name_root} || 'command';
	my $command_sub      = sub {
		my ( $value, $conf ) = @_;
		chomp( $value );
		$counter++;
		print "$screen_name_root\_$counter,$value$/" if $self->cfg->{vocal};
		return "$screen_name_root\_$counter", qq|$value|;
	};
	$self->run_on_min_screens( $value_sub, $command_sub, $self->cfg() );
	close( $ifh );

}

1;

package main;
main();

sub main {

	my $self = Obj->new();
	$self->get_config(
		[
			qw/
			  in_file
			  /
		],
		[
			qw/
			  sleep_time
			  min_screens
			  vocal
			  name_root
			  /
		],
		{
			required => {
				in_file => "Path to input file",
			},
			optional => {
				sleep_time  => "Interval between checks for minimum concurrent screens",
				min_screens => "Desired minimum concurrent screens",
				name_root   => "Base name of all screens to be created (e.g. 'mysql' will produce mysql_1, mysql_2 etc",
				vocal       => "Print command when execution begins",
				live        => "Execute screen commands instead of printing them",
			}
		}
	);
	$self->process();

}
