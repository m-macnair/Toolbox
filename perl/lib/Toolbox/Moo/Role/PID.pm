package Toolbox::Moo::Role::PID;
our $VERSION = 'v1.0.1';

##~ DIGEST : 783fe5eab5e7b76fc10625c8fb72722b
# do pids - ideally with wrappers around main() calls
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

sub startpid {
	my ( $self ) = @_;
	open( my $fh, '>', $self->pid_path() );
	print $fh time;
	close $fh;
}

sub stoppid {
	my ( $self ) = @_;
	unlink $self->pid_path();
}

1;
