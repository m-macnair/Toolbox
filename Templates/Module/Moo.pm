use strict;

package Some::Module;

our $VERSION = 'v1.0.1';
##~ DIGEST : 90859d4ad0cf0a89720c6f5ce38facf0

use Moo;
use 5.006;
use warnings;

=head1 NAME
	~
=head1 VERSION & HISTORY
	<breaking revision>.<feature>.<patch>
	1.0.0 - <date>
		<actions>
	1.0.0 - <date unless same as above>
		The Mk1
=cut

=head1 SYNOPSIS
	TODO
=head2 TODO
	Generall planned work
=head1 ACCESSORS
=cut

ACCESSORS: {

	has something => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return 0 }
	);
}

=head1 SUBROUTINES/METHODS
=head2 PRIMARY SUBS
	Main purpose of the module
=head3
=cut

sub do_something {
	my ( $self, $p ) = @_;
	$p ||= {};
}

=head2 SECONDARY SUBS
	Actions used by one or more PRIMARY SUBS that aren't wrappers
=cut

sub validate_some_value {
	my ( $self, $p, $value ) = @_;
	$p ||= {};
	die unless ( $p->{$value} );
}

=head2 WRAPPERS
=head3 external_function
=cut

=head1 AUTHOR
	mmacnair, C<< <mmacnair at cpan.org> >>
=head1 BUGS
	TODO Bugs
=head1 SUPPORT
	TODO Support
=head1 ACKNOWLEDGEMENTS
	TODO
=head1 COPYRIGHT
 	Copyright 2020 mmacnair.
=head1 LICENSE
	TODO
=cut

1;
