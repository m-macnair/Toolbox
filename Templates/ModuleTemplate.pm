package Some::Module;
use strict; 
use 5.006;
use warnings;


=head1 NAME
	~
=head1 VERSION
	Version 0.01
=cut

our $VERSION = '0.01';


=head1 SYNOPSIS
	TODO
=head1 EXPORT
	None
=head1 SUBROUTINES/METHODS
=head2 Facilitators
	Specific to this module
=head3 _init
	Separate class instantiation and configuration for when that's a good idea
=cut

sub _init {
	my ( $self, $conf ) = @_;
	return {pass => 1};
}

=head2 Critical Path
	Replacements for parent modules that carry out 'The thing we want to do'
=cut

sub function2 {
}

=head1 AUTHOR

mmacnair, C<< <mmacnair at cpan.org> >>

=head1 BUGS

	TODO Bugs

=head1 SUPPORT

	TODO Support

=head1 ACKNOWLEDGEMENTS
	TODO 

=head1 LICENSE AND COPYRIGHT

Copyright 2018 mmacnair.

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of mmacnair's Organization
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;