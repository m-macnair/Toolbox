use strict;
use warnings;
use Data::Dumper;
use Parse::Netstat qw(parse_netstat);
main( @ARGV );

sub main {
	my ( $port, $savepath ) = @_;
	unless ( $port && int( $port ) == $port ) {
		die "No port provided";
	}
	my $res = parse_netstat( output => join( "", `netstat -nt` ), flavor => 'linux' );

	if ( $res->[0] == 200 ) {
		my $found;
		for my $line ( @{$res->[2]->{active_conns}} ) {
			if ( $line->{local_port} == $port ) {
				$found = 1;
				last;
			}
		}
		if ( $found ) {
			hasconnection( $port, $savepath );
		} else {
			noconnection( $port . $savepath );
		}

	} else {
		warn "Failure in netstat command (?)";
	}
	my $target = "BenderOpolis_" . isoday() . '.wld';
	my $cmd    = "aws s3 cp $savepath s3://haventree-games/terraria/$target";
	warn $cmd;
	`$cmd`;
}

sub noconnection {
	my ( $port, $savepath ) = @_;
	if ( -e "/var/monitor.$port" ) {
		noconnectionlimit( $port, $savepath );
	} else {
		`touch /var/monitor.$port`;
	}

}

sub hasconnection {
	my ( $port, $savepath ) = @_;
	if ( -e "/var/monitor.$port" ) {
		unlink( "/var/monitor.$port" );
	}

}

sub noconnectionlimit {
	my ( $port, $savepath ) = @_;

}

sub isoday {

	my @t = localtime( time );
	$t[5] += 1900;
	$t[4]++;
	return sprintf '%04d-%02d-%02d', @t[ 5, 4, 3 ];
}
