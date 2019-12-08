use strict;

package Toolbox::FileList;
use base "Toolbox::SimpleClass";

sub findfiles {
	my ( $self, $dir, $sub ) = @_;
	require Toolbox::Common;
	Toolbox::Common::findfilesub( $dir, $sub );
}

1;
