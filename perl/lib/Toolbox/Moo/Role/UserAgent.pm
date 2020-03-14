package Toolbox::Moo::Role::UserAgent;
our $VERSION = '0.02';

##~ DIGEST : d10960452f623a0c281ce7cf3300e321
# Do http requests
use Moo::Role;

ACCESSORS: {
	has pid_root => (
		is      => 'rw',
		lazy    => 1,
		default => sub { "$ENV{HOME}" }
	);
	has pid_path => (
		is      => 'rw',
		lazy    => 1,
		default => sub { $_[0]->pid_root . '/.pid_' . $$ }
	);
}

sub postjson {

	my ( $self, $url, $q, $p ) = @_;
	$p ||= {};
	my $ua = $self->lwpuseragent();
	$ua->timeout( $p->{timeout} || 1000 );
	require HTTP::Request;
	my $req = HTTP::Request->new( 'POST', $url );
	$req->header( 'Content-Type' => 'application/json' );
	$req->content( $self->json->encode( $data ) );
	my $result = $ua->request( $req );
	return $result;

}

sub postretrievejson {

	my ( $self, $url, $q ) = @_;
	my $response = $self->postjson( $url, $data );
	if ( $response->is_success ) {
		try {
			my $jsondef = $self->json->decode( $response->decoded_content );
			return {
				pass => 'data',
				data => $jsondef
			  }
		}
		catch {
			return {fail => "JSON decoding failure : $_"};
		};
	} else {
		return {fail => $response->status_line};
	}

}

1;
