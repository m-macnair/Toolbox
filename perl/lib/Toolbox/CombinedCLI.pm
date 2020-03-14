use strict;

package Toolbox::CombinedCLI;
our $VERSION = 'v1.0.1';
##~ DIGEST : cd897eca985bb32179366816fb16503e

=head1 Toolbox::CombinedCLI
	Standard overlay to Config::Any::Merge and friends
=cut

# TODO exporter
require Getopt::Long;
require Config::Any::Merge;
require Hash::Merge;
use Data::Dumper;
use Carp;

=head2 get_config 
	My Way - one or two arrays, with config_file/dir as automatic optional which loads config files before choking
=cut

sub get_config {
	my ( $required, $optional, $p ) = @_;

	$required ||= [];
	$optional ||= [];
	$p        ||= {};
	my $default = $p->{'default'} || {};

	push( @{$optional}, qw/config_file config_dir cfg / );
	my $config_href;
	Getopt::Long::Configure( qw( default ) );
	my @options;

	#generate the value types and reference pointers required by GetOptions
	for my $key ( explode_array( [ @{$required}, @{$optional} ] ) ) {
		push( @options, "$key=s" );
		push( @options, \$$config_href{$key} );
	}

	#capture the arguments
	Getopt::Long::GetOptions( @options ) or Carp::confess( "Error in command line arguments : $!" );
	my $file_config = {};

	#it's assumed that a config dir might be overwritten by single config file, e.eg standard/ + scenario.conf
	if ( $config_href->{config_dir} ) {
		$file_config->{config_dir} = $config_href->{config_dir};
		config_file_dir( $file_config );
	}
	if ( $config_href->{config_file} || $config_href->{cfg} ) {

		$file_config->{config_file} = $config_href->{config_file} || $config_href->{cfg};
		config_file_dir( $file_config );
	}

	#hash::merge by design means that empty keys from config_href will overwrite those filled in by the file config
	for my $key ( keys( %{$config_href} ) ) {
		delete( $config_href->{$key} ) unless defined( $config_href->{$key} );
	}

	#Cargo Cultin'
	%$config_href = %{Hash::Merge::merge( $file_config, $config_href, $default )};

	for my $key ( @{$required} ) {
		THISKEY: {
			my $ref = ref( $key );

			#arrays in required mean 'one of'
			if ( $ref eq 'ARRAY' ) {
				for my $subcheck ( @{$key} ) {
					if ( defined( $config_href->{$subcheck} ) ) {

						#all good - continue
						next THISKEY;
					}
				}
				Carp::confess( "None of [" . join( ',', @{$key} ) . "] provided through configuration" );
			} elsif ( $ref ) {
				Carp::confess( "[$ref] provided in get_config - can't parse" );
			} else {
				unless ( $config_href->{$key} ) {
					Carp::confess( "[$key] Not provided through configuration" );
				}
			}
		}
	}

	#aaaand we're done
	return $config_href;
}

=head2 array_config
	take one or two array refs, with required and optional command line parameters respectively and merge them into a href containing the command line values, croaking if any required are missing 
=cut

sub array_config {
	my ( $required, $optional, $params ) = @_;
	$required ||= [];
	$optional ||= [];
	my $return;
	Getopt::Long::Configure( qw( default ) );
	my @options;

	#generate the value types and reference pointers required by GetOptions
	for my $key ( explode_array( [ @{$required}, @{$optional} ] ) ) {
		push( @options, "$key=s" );
		push( @options, \$$return{$key} );
	}
	Getopt::Long::GetOptions( @options )
	  or die( "Error in command line arguments\n" );

	#this is ugly, but it handles:
	#I must have $this
	#I must have $this and ($this or $this)
	for my $key ( @{$required} ) {
		if ( ref( $key ) ) {
			my $go;
			for my $level_1 ( @{$key} ) {
				if ( $return->{$level_1} ) {
					$go = 1;
					last;
				}
			}
			croak( "Did not find required switch in [" . join( ',', @{$key} ) . "]" )
			  unless $go;
		} else {
			croak( "Did not find required value [$key] " ) unless $return->{$key};
		}
	}
	return $return; #return!
}

=head3 explode_array
	Turn arrays which may contain other arrays into a single stack of values
=cut

sub explode_array {
	my ( $array ) = @_;
	my @return;
	for ( @{$array} ) {
		if ( ref( $_ ) ) {
			push( @return, explode_array( $_ ) );
		} else {
			push( @return, $_ );
		}
	}
	return @return;
}

sub check_array {
	my ( $return, $array, $params ) = @_;
	for my $key ( @{$array} ) {
		if ( ref( $key ) ) {
			my $result = check_array( $return, $key );
			my $ok;
			for my $switch_key ( @{$key} ) {
				if ( $return->{$switch_key} ) {
					$ok = 1;
					last;
				}
			}
		} else {
		}
	}
	return 1;
}

=head2 standard_config
	Typical use case; config ascends from hard coded -> config file -> command line (-> wxwidets UI)
	in nearly every situation, this will be all that's needed, as it does everything involved in getting a usable $c
	takes a hash ref of system set values, and explicit types for getopt::long, or nothing, 
	then runs through the correct sequence of overwrites to return a single config hashref
	validation is best kept outside of this function as there will be cases we want blank config files and so on.
=cut

sub standard_config {
	my ( $c, $types ) = @_;
	$c = {} unless $c;
	config_path( $c );
	if ( $$c{config_file} or $$c{config_dir} ) {
		warn "no configuration created from a defined config path"
		  unless config_file_dir( $c );
	}
	cli_smart_overwrite( $c, $types );
	return $c;
}

=head2 config_path
	load command line config for config file override
	*must* be passed a hash ref or will choke.
=cut

sub config_path {
	my ( $c ) = @_;
	my $options = [
		'config=s'     => \$$c{config_file},
		'config_dir=s' => \$$c{config_dir},
	];
	Getopt::Long::Configure( qw( pass_through ) ); #ignore everything that isn't config or cfg_dir
	Getopt::Long::GetOptions( @$options )
	  or die( "Error in command line arguments\n" );
}

=head2 step 2
	parse config file/directory, on the assumption that $c has the path to config files or directory
	returns 1 if config work was carried out.
=cut

sub config_file_dir {
	my ( $c ) = @_;
	my $file_config = {};
	if ( $$c{config_file} ) {
		if ( -e $$c{config_file} && -f _ && -r _ ) {
			$file_config = Config::Any::Merge->load_files(
				{
					files   => [ $$c{config_file} ],
					use_ext => 1
				}
			) or die "failed to load configuration file : $!";
		} else {
			warn "failed file path: $!";
			return 0;
		}

		#this following section has never been tested
	} elsif ( $$c{config_dir} ) {
		if ( -e $$c{config_dir} && -d _ && -r _ ) {
			my @cfiles;
			File::Find::find(
				{
					wanted => sub {
						if (
							-f $File::Find::name

							# 	&& -r _
						  )
						{
							push( @cfiles, $File::Find::name );
						} else {

							# warn $File::Find::name;
						}
					},
					no_chdir => 1
				},
				$$c{config_dir}
			);
			$file_config = Config::Any::Merge->load_files(
				{
					files   => [@cfiles],
					use_ext => 1
				}
			) or die "failed to load configuration file : $!";
		} else {
			warn "failed file path: $!";
			return 0;
		}
	}
	if ( keys( %$file_config ) ) {

		# warn join $/, keys %$file_config;
		# warn "file config";
		%$c = %{Hash::Merge::merge( $c, $file_config )};
		return 1;
	} else {
	}
}

=head2 cli_dumb_overwrite
	make manually configured $options alterable from the commandline
=cut

sub cli_dumb_overwrite {
	my ( $c, $options ) = @_;
	Getopt::Long::Configure( qw( default ) );
	Getopt::Long::GetOptions( @$options )
	  or die( "Error in command line arguments\n" );
}

=head2 cli_smart_overwrite
	from current $c keys, allow command line to overwrite. 
	optional $types hashref contains
	key => {
type => s, #s = string - usually good enough
target => $value, # this is especially useful for defining arrays from command line - see the getopt::long for details
	}
	Under default, this will choke when faced with a value it doesn't know about (from either the initialising hash or the config file)
	optional $getoptions_arrayref can be supplied to modify how getopt::Long processes applied values
=cut

sub cli_smart_overwrite {
	my ( $c, $types, $getoptions_arrayref ) = @_;
	my $options = [];
	for my $key ( keys %$c ) {
		if ( defined( $$types{$key} ) ) {
			push( @$options, "$key=$$types{$key}{type}" );
			push( @$options, $$types{$key}{target} );
		} else {
			push( @$options, "$key=s" );
			push( @$options, \$$c{$key} );
		}
	}
	if ( $getoptions_arrayref ) {
		Getopt::Long::Configure( @$getoptions_arrayref );
	} else {
		Getopt::Long::Configure( qw( default ) );
	}
	Getopt::Long::GetOptions( @$options )
	  or die( "Error in command line arguments\n" );
}

#step 4. verify running config

=head2 LICENSE INFORMATION
	This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0
=cut

1;
