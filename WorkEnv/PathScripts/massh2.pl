#!/usr/bin/perl
use strict;
use warnings;
use Net::OpenSSH::Parallel;
use Term::ReadKey;
use Carp;
use Data::Dumper;
use Net::OpenSSH::Parallel::Constants qw(:error :on_error);
use File::stat;
use Expect;
use Toolbox::CombinedCLI;
use Toolbox::FileSystem;
use Toolbox::FileIO::CSV;

# use Template;
my $c = {};
main();

sub main() {

	$c = Toolbox::CombinedCLI::get_config( [], [qw/ meta_list user host_list command_list defaultuser /] );
	use Data::Dumper;

	# 	die Dumper($c);
	if ( $c->{meta_list} ) {
		Toolbox::FileSystem::checkfile( $c->{meta_list} );
		$c->{user} ||= $c->{defaultuser} ? $ENV{USER} : prompt( 'enter user', $ENV{USER} );
		$c->{pass} = prompt( 'enter pass', undef, {hidden => 1} );
		Toolbox::FileIO::CSV::suboncsv(
			sub {
				my ( $row ) = @_;

				#handle blank rows
				next unless $row->[0];
				Toolbox::FileSystem::checkfile( $row->[0] );
				Toolbox::FileSystem::checkfile( $row->[1] );
				process_pair( $c, @{$row} );
				return 1;
			},
			$c->{meta_list}
		);
	} else {
		check_file_if_provided( $c->{hostlist} );
		check_file_if_provided( $c->{commandlist} );
		my $command_list = $c->{command_list} || promptforfile( 'Enter command list file', [qw# ./commandlist.csv ./mash_commands.csv#] );
		my $host_list    = $c->{host_list}    || promptforfile( 'Enter host file',         [qw# ./hostlist.csv ./mash_hosts.csv #] );
		$c->{pass} = prompt( 'enter pass', undef, {hidden => 1} );
		$c->{user} ||= $c->{defaultuser} ? $ENV{USER} : prompt( 'enter user', $ENV{USER} );
		process_pair( $c, $command_list, $host_list );
	}
	precheck();

}

sub process_pair {

	my ( $c, $command_list, $host_list ) = @_;

	#Actual Work
	my $pssh       = Net::OpenSSH::Parallel->new( reconnections => 2, );
	my $knownhosts = "$ENV{HOME}/.ssh/known_hosts";
	open( my $fh, '<', $knownhosts ) or die "Failed to open $knownhosts - $!";
	while ( <$fh> ) {
		$c->{knownhostsbuffer} .= $_;
	}
	my @sshstack;
	close( $fh );
	SETUPHOSTS: {
		Toolbox::FileIO::CSV::suboncsv(
			sub {
				my ( $row, $rownum, $continue ) = @_;
				my $host = join( '', @{$row} );
				chomp( $host );
				$host =~ s| ||g;
				return unless ( $host );
				my $options = {
					user     => $c->{user},
					password => $c->{pass},
				};

				# single_ssh( $host, $options );
				known_host( $c, $host );

				#non hrefs still cause me distress
				$pssh->add_host( $host, %$options, on_error => OSSH_ON_ERROR_ABORT_ALL );
				return 1;
			},
			$host_list
		);
	}
	print $/;
	SETUPCOMMANDS: {
		Toolbox::FileIO::CSV::suboncsv(
			sub {
				my ( $row ) = @_;

				#detect if the command is a shell command or an scp action
				my $command;
				if ( $row->[0] eq 'legacy_sudo' ) {
					shift( @{$row} );
					print "ACTION: legacy_sudo " . join( ' ', @{$row} ) . $/;
					$pssh->push( '*', parsub => \&legacy_sudo, @{$row} );
				} elsif ( $row->[0] eq 'sudo' ) {
					shift( @{$row} );
					print "ACTION: sudo " . join( ' ', @{$row} ) . $/;
					$pssh->push( '*', parsub => \&sudo, @{$row} );
				} else {

					#BEWARE; scp_get/put using a path with a space will NOT do the right thing - you'll need to pre-chomp it
					for ( qw/scp_put scp_get command/ ) {
						if ( $row->[0] eq $_ ) {
							$command = $_;
						}
					}
					unless ( $command ) {
						unshift( @$row, 'command' );
					}
					print "ACTION: " . join( ' ', @{$row} ) . $/;
					$pssh->push( '*', @$row );
				}
				return 1;
			},
			$command_list
		);
	}
	$pssh->run;
	use Data::Dumper;
	my $errors = [ $pssh->get_errors ];
	if ( @{$errors} ) {
		while ( @{$errors} ) {
			my ( $host, $error ) = ( shift( @{$errors} ), shift( @{$errors} ) );
			print "ERROR:\t[$host]\t:\t$error$/";
		}
	} else {
		print "STATUS: No errors$/";
	}
	print "STATUS: Complete!$/";

}

sub precheck {

	my @paths = ( $ENV{HOME}, "$ENV{HOME}.libnet-openssh-perl/", );
	for my $path ( @paths ) {
		my $info = File::stat::stat( $path ) or die "Failed to stat $path! : $!";
		my $mode = substr( sprintf( "04%o", ( $info->mode & 07777 ) ), 3 );
		my ( $group, $world ) = split( //, $mode );
		if ( ( $group > 5 ) or ( $world > 5 ) ) {
			die "OpenSSH will cause problems with $path!$/suggest chmod 755 $path$/";
		}
	}

}

sub prompt {

	my ( $prompt, $default, $opt ) = @_;
	$opt ||= {};
	my $promptstring = $prompt;
	$promptstring .= " [$default]" if $default;
	$promptstring .= ' :';
	while ( 1 ) {
		print $promptstring;
		$| = 1; #flush
		Term::ReadKey::ReadMode( 'noecho' ) if $opt->{hidden};
		my $res = Term::ReadKey::ReadLine( 0 );
		if ( $opt->{hidden} ) {
			print $/;
			Term::ReadKey::ReadMode( 'restore' );
		}
		chomp( $res );
		$res = $res || $default;
		return $res if $res;
		print "$/must provide a value$/" unless $opt->{optional};
	}

}

sub promptforfile {

	my ( $prompt, $defaults, $opt ) = @_;

	#go through all possible defaults and offer
	for my $file ( @$defaults ) {
		if ( -f $file ) {
			while ( 1 ) {
				$file = prompt( $prompt, $file, $opt );
				if ( -f $file ) {
					return $file;
				} else {
					print "file [$file] not found";
				}
			}
		}
	}

	#no defaults left/supplied, so bitch for a file
	while ( 1 ) {
		my $file = prompt( $prompt, undef, $opt );
		if ( -f $file ) {
			return $file;
		} else {
			print "file [$file] not found";
		}
	}

}

sub single_ssh {

	my ( $host, $opts ) = @_;
	my $ssh = Net::OpenSSH->new( $host, %$opts );
	$ssh->error and die "Can't ssh to $host: " . $ssh->error;
	return $ssh;

}

sub check_file_if_provided {

	my ( $path ) = @_;
	if ( $path ) {
		Toolbox::FileSystem::checkfile( $path );
	}

}

sub known_host {

	my ( $c, $host ) = @_;
	if ( $c->{knownhostsbuffer} =~ m/$host/ ) {
		print "HOST: Known; $host$/";
	} else {
		`ssh-keyscan -H $host >> $ENV{HOME}/.ssh/known_hosts`;
		print "HOST: Unknown; [$host]$/";
	}

}

sub sudo {

	my ( $label, $ssh, @cmd ) = @_;
	$ssh->system( {stdin_data => "$c->{password}\n"}, 'sudo', '-Skp', '', '--', @cmd );

}

#for when sudo is too old to do what we want
sub legacy_sudo {

	my ( $label, $ssh, @cmd ) = @_;
	use Data::Dumper;
	my ( $pty ) = $ssh->open2pty( 'sudo -Sk ' . join( ' ', @cmd ) );
	my $expect = Expect->init( $pty );
	$expect->raw_pty( 1 );
	my $timeout = 60;
	$expect->expect( $timeout, ":" );
	$expect->send( "$c->{pass}\n" );
	$expect->expect( $timeout, "\n" );
	$expect->raw_pty( 0 );

	# 	die "wtf";
	while ( <$expect> ) { print $_ unless $_ =~ $c->{pass} }
	close $expect;
	return 1;

}
print "$/done$/";
