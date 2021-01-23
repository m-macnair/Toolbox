#!/usr/bin/perl
# ABSTRACT: given a template json file and a csv representing variables, create json files for each row overwriting the template
our $VERSION = 'v0.0.1';

##~ DIGEST : 0a842c7a43fe095742b16052fe2f80ec

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


  /;


sub process {
	my ( $self ) = @_;
	my $template_def = $self->json_load_file($self->cfg->{json});
	$self->json->pretty( 1 );
	$self->json->canonical( 1 );	
	my $out_dir = $self->cfg->{out_dir} || './';
	my $output_file_name_column = $self->cfg->{output_file_name_column} || 'output_file_name'; 
	$self->sub_on_csv_href(sub {
		my ($row_hash) = @_;
		die "no determined output name for row" unless $row_hash->{$output_file_name_column};
		my $new_def = {
			%{$template_def},
			%{$row_hash},
		};
		
		my $ofh = $self->ofh("$out_dir/$row_hash->{$output_file_name_column}.json");
		print $ofh $self->json->encode($new_def);
	},$self->cfg->{csv});
	$self->close_fhs();
}
1;

package main;

main();

sub main {
	my $self = Obj->new();
	$self->get_config(
		[qw/
			json
			csv
		/],
		[
			qw/
				out_dir
				output_file_name_column
			  /
		],
		{
			required => {
				json => 'Initial template to overwrite',
				csv => 'List of values to apply to the template',
			},
			optional => {
				out_dir => 'Directory to write out template results; defaults to ./ ',
				output_file_name_column => 'Explicit column to use as the output file name',
			}
		}
	);
	$self->process();

}
