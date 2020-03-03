package Toolbox::Moo::Role::Debug;
our $VERSION = '0.02';

##~ DIGEST : d42b23d7d0996e52f57e076537977641
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
