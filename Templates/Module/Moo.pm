# ABSTRACT :
package Some::Module;
our $VERSION = 'v0.0.2';

##~ DIGEST : b3fb2d62e76e748ad99662538395288e
use strict;
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
=head2 LIFECYCLE SUBS
=cut

sub BUILD {
	my ( $self, $args ) = @_;

}

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
 	Copyright 2021 mmacnair.
=head1 LICENSE
	TODO
=cut

1;
