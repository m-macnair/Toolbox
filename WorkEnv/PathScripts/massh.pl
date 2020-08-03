#!/usr/bin/perl
DEPENDENCIES: {
	use Net::OpenSSH::Parallel;
	use Term::ReadKey;
	use Text::CSV;
	use Carp;
	use Data::Dumper;
	use Net::OpenSSH::Parallel::Constants qw(:error :on_error);
	use File::stat;
	use strict;
	use warnings;
}
main();

sub main() {
	precheck();

	my $commandlist = promptforfile( 'Enter command list file', [qw# ./commandlist.csv ./mash_commands.csv# ] );
	my $hostlist    = promptforfile( 'Enter host file',         [qw# ./hostlist.csv ./mash_hosts.csv # ]);
	my $user = prompt( 'enter user', $ENV{USER} );
	my $pass = prompt( 'enter pass', undef, {hidden => 1} );

	#Actual Work
	my $pssh = Net::OpenSSH::Parallel->new( reconnections => 2, );
	my $knownhostsbuffer;
	my $knownhosts = "$ENV{HOME}/.ssh/known_hosts";
	open( my $fh, '<', $knownhosts ) or die "Failed to open $knownhosts - $!";
	while ( <$fh> ) {
		$knownhostsbuffer .= -$_;
	}
	my @sshstack;
	close( $fh );
	SETUPHOSTS: {
		processcsv(
			{
				path  => $hostlist,
				'sub' => sub {
					my ( $row, $rownum, $continue ) = @_;
					my $host = join('',@{$row});
					chomp($host);
					return unless($host);
					
					my $options = {
						user => $user, 
						password => $pass, 
						
					};
					single_ssh($host,$options);
					
					if ( $knownhostsbuffer =~ m/$row->[0]/ ) {
# 						print "HOST: Known; $row->[0]$/";
					} else {
						`ssh-keyscan -H $row->[0] >> $ENV{HOME}/.ssh/known_hosts`;
						print "HOST: Unknown; $row->[0]$/";
					}

					#non hrefs still cause me distress
					$pssh->add_host( $row->[0],%$options, on_error => OSSH_ON_ERROR_ABORT_ALL  );

				}
			}
		);
	}

	print $/;
	SETUPCOMMANDS: {
	
		
	
	
		processcsv(
			{
				path  => $commandlist,
				'sub' => sub {
					my ( $row, $rownum, $continue ) = @_;

					#detect if the command is a shell command or an scp action
					my $command;
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
			}
		);
	}

	$pssh->run;
	use Data::Dumper;
	my $errors = [ $pssh->get_errors];

	if(@{$errors}){
		while(@{$errors}){
			my ($host,$error) = (shift(@{$errors}),shift(@{$errors}));
			print "ERROR:\t$host\t:\t$error$/";
		}
	} else{ 
		print "STATUS: No errors$/";	
	}
	print "STATUS: Complete!$/";
}


sub precheck { 



	my @paths = (
		$ENV{HOME},
		"$ENV{HOME}.libnet-openssh-perl/",
	);
	for my $path (@paths){
		
		my $info    = File::stat::stat($path) or die "Failed to stat $path! : $!";
		my $mode = substr(sprintf("04%o", ($info->mode & 07777)),3);
		my ($group,$world) = split(//,$mode);
		if(($group > 5) or  ($world > 5)){
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
	for my $file (@$defaults){

		if(-f $file ){
			
			while(1){
				$file = prompt( $prompt, $file, $opt );
				if ( -f $file ){
					return $file;
				} else { 
					print "file [$file] not found";
				}
			}
		}
	}
	#no defaults left/supplied, so bitch for a file
	while(1){
		$file = prompt( $prompt, undef, $opt );
		if ( -f $file ){
			return $file;
		} else { 
			print "file [$file] not found";
		}
	}
}

sub processcsv {

	my ( $p ) = @_;
	my $fh = $p->{fh};
	unless ( $fh ) {
		return {fail => "File [ $p->{path} ]not present", nofile => 1}
		  unless ( -e $p->{path} );
		open $fh, "<:encoding(utf8)", $p->{path}
		  or Carp::croak( "Failed to open [$p->{path}] : $!" );
	}
	my $csv = $p->{csv};
	unless ( $csv ) {
		require Text::CSV;
		$csv = Text::CSV->new( {binary => 1} )
		  or Carp::confess( {fail => "Cannot use CSV: " . Text::CSV->error_diag()} );
	}
	my $rownum   = 0;
	my $method   = $p->{method};
	my $continue = 1;
	my $sub      = $p->{'sub'};
	while ( my $row = $csv->getline( $fh ) ) {

		#skip commented rows
		next if ( index( $row->[0], '#' ) == 0 );
		if ( $method ) {
			die "nope";
		} else {
			&$sub( $row, $rownum, \$continue, $p );
		}
		$rownum++;
		last unless $continue;
	}
	unless ( $p->{noclose} ) {
		close $fh or Carp::croak( "Failed to close [$p->{path}] : $!" );
	}

	#rownum would make sense as the pass value, but 0 could be acceptable and the standard "did something" check would fail
	return {pass => 1, rows => $rownum};

}

sub single_ssh  {
	my ($host,$opts) = @_;

	my $ssh =  Net::OpenSSH->new(
		$host,
		%$opts
	);
	$ssh->error and die "Can't ssh to $host: " . $ssh->error;
	return $ssh;
}
