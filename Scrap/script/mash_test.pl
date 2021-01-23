use Net::OpenSSH;
use Net::OpenSSH::Parallel;
my @hosts = qw/
  192.168.0.3
  192.168.0.16
  /;
for my $host ( @hosts ) {
	my $opts = {
		expand_vars => 1,
		user        => 'm',
		async       => 1
	};
	my $ssh = Net::OpenSSH->new( $host, %$opts );
	$ssh->error and die "Can't ssh to $host: " . $ssh->error;
}

# my $pssh = Net::OpenSSH::Parallel->new();
# $pssh->add_host($_) for @hosts;
#
# # $pssh->push('*', scp_put => '/local/file/path', '/remote/file/path');
# $pssh->push('*', command => 'ls -lah ~ > ~/ls.txt',);
#
# $pssh->push('*', scp_get => '~/ls.txt', '%HOST%_ls.txt');
#
# $pssh->run;
