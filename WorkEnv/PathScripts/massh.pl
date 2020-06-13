#!/usr/bin/perl
DEPENDENCIES: {
	use Net::OpenSSH::Parallel;
	use Term::ReadKey;
	use Text::CSV;
	use Carp;
	use Data::Dumper;
	use Net::OpenSSH::Parallel::Constants qw(:error :on_error);
}
main();

sub main() {

	my $file;
	my $user = prompt( 'enter user', $ENV{USER} );
	my $pass = prompt( 'enter pass', undef, {hidden => 1} );

	my $commandlist = promptforfile( 'Enter command list file', 'commandlist.csv' );
	my $hostlist    = promptforfile( 'Enter host file',         'hostlist.csv' );

	#Actual Work
	my $pssh = Net::OpenSSH::Parallel->new( reconnections => 2, );
	my $knownhostsbuffer;
	my $knownhosts = '~/.ssh/known_hosts'
	open (my $fh,'<',$knownhosts) or die "Failed to open $knownhosts - $!";
	while(<$fh>){
		$knownhostsbuffer .=- $_;
	}
	close($fh);
	SETUPHOSTS: {
		processcsv(
			{
				path  => $hostlist,
				'sub' => sub {
					my ( $row, $rownum, $continue ) = @_;
					if($knownhostsbuffer =~ m/$row->[0]/){
						print "HOST: Known; $row->[0]$/";	
					}else {
						`ssh-keyscan -H $row->[0] >> ~/.ssh/known_hosts`;
						print "HOST: Unknown; $row->[0]$/";	
					}

					# non hrefs still cause me distress
					$pssh->add_host( $row->[0], user => $user, password => $pass, on_error => OSSH_ON_ERROR_ABORT_ALL );
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

					#detect if the command is a command or an scp action
					my $command;
					for ( qw/scp_put scp_get command/ ) {
						if ( $row->[0] eq $_ ) {
							$command = $_;
						}
					}
					unless ( $command ) {
						unshift( @$row, 'command' );
					}
					print "ACTION: " . join( ',', @{$row} ) . $/;
					$pssh->push( '*', @$row );
				}
			}
		);
	}

	$pssh->run;
	print "ERRORS: " . $pssh->get_errors;
	print "STATUS: Complete!$/"
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

	my ( $prompt, $default, $opt ) = @_;
	my $file = $default;
	while ( 1 ) {
		$file = prompt( $prompt, $default, $opt );
		last if ( -e $file );
		print "$file not found";
	}
	return $file;

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
