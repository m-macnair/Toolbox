use strict; # applies to all packages defined in the file

package Toolbox::Whatever;
use Carp qw/cluck confess/; # does *NOT* applie to all packages in file
our $VERSION = '0.01';

##~ DIGEST : a051047e21d72ef8e6ef9904ff331984

=head1 NAME
	~
=head1 VERSION & HISTORY
	0.0.1 - <date>
	0.0.0 - <date unless same as above>
=head1 SYNOPSIS
	TODO
=head2 TODO
	Generall planned work
=head1 EXPORT



=head1 CODE
=head2 MAJOR SUBS
	Subs that use other subs to an abstract or specific end
=cut

sub dosomething {
	my ( $p ) = @_;
}

=head2 MINOR SUBS
	Subs used by major subs, or other minor subs
=cut

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
