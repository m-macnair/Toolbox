package Toolbox::Moo::Role::Debug;
our $VERSION = 'v1.0.1';

##~ DIGEST : 8a09e1101e38af268e55d53082823aac
use Moo::Role;

ACCESSORS: {

	has debug => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return $ENV{DEBUG} }
	);

}

sub debug_msg {
	my ( $self, $msg, $min_lvl ) = @_;
	$min_lvl ||= 1;
	my $debug = $self->debug || 0;
	print "[DEBUG] $msg$/" if $debug >= $min_lvl;
}

1;
