#!/usr/bin/perl
# ABSTRACT: given a text file and some non-default values, execute each line in the text file in its own screen in parallel
our $VERSION = 'v0.0.8';
##~ DIGEST : a9f47172ce7a9ef23769d772cffacd42
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
  Moo::GenericRole::InteractiveCLI
  Moo::GenericRole::MCEShared
  /;

sub process {

	my ( $self ) = @_;
	$self->check_file( $self->cfg->{in_file} );
	open( my $ifh, '<', $self->cfg->{in_file} ) or die $!;
	my $value_sub = sub {

		# 		warn 'value sub';
		return <$ifh>;
	};
	my $counter          = 0;
	my $screen_name_root = $self->cfg->{name_root} || 'command';
	my $command_sub      = sub {

		# 		warn 'Command sub';
		my ( $value, $conf ) = @_;
		chomp( $value );
		$counter++;
		print "$screen_name_root\_$counter,$value$/" if $self->cfg->{vocal};
		return "$screen_name_root\_$counter", qq|$value|;
	};
	$self->prefork_share_accessors( [qw/ cfg running_screen_map /] );
	my $screen_runner_pid = $self->forked_method( 'run_on_min_screens', [ $value_sub, $command_sub, $self->cfg() ] );
	$self->main_menu();
	kill 1, $screen_runner_pid;
	close( $ifh );

}

sub main_menu {
	my ( $self ) = @_;
	$self->numerical_term_readline_menu(
		{
			prompt    => "Choose Submenu",
			choices   => [ {'Screen #' => 'min_screen_menu'}, ],
			'default' => 'Screen #',
		}
	);
}

sub min_screen_menu {
	my ( $self ) = @_;

	$self->numerical_term_readline_menu(
		{
			prompt      => $self->min_screen_menu_prompt_string(),
			choices     => [ {'+1' => 'add_one'}, {'+5' => 'add_five'}, {'-1' => 'remove_one'}, {'-5' => 'remove_five'}, {'Reload Status' => 'refres_min_screen_menu'} ],
			quit_string => 'Back',
			'default'   => 'Reload Status',
		}
	);
	return 1;
}

sub min_screen_menu_prompt_string {
	my ( $self ) = @_;

	return "Current Running Screens: " . $self->check_running_screens() . "$/Change minimum screens (" . $self->cfg->{min_screens} . ")",;
}

sub refres_min_screen_menu {
	my ( $self, $p ) = @_;

	$p->{prompt} = $self->min_screen_menu_prompt_string();
	return 1;
}

sub add_one {
	my ( $self, $p ) = @_;

	$self->cfg->{min_screens}++;
	$p->{prompt} = $self->min_screen_menu_prompt_string();
	return 1;
}

sub add_five {
	my ( $self, $p ) = @_;
	$self->cfg->{min_screens} += 5;
	$p->{prompt} = $self->min_screen_menu_prompt_string();
	return 1;
}

sub remove_one {
	my ( $self, $p ) = @_;
	$self->cfg->{min_screens}--;
	$p->{prompt} = $self->min_screen_menu_prompt_string();
	return 1;
}

sub remove_five {
	my ( $self, $p ) = @_;
	$self->cfg->{min_screens} -= 5;
	$p->{prompt} = $self->min_screen_menu_prompt_string();
	return 1;
}

1;

package main;
main();

sub main {
	use MCE::Shared;
	my $self = MCE::Shared->share( {module => 'Obj'} );

	$self->get_config(
		[
			qw/
			  in_file
			  min_screens
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
