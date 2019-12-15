use strict;
use warnings;

package Toolbox::Core;
use Module::Runtime qw/ require_module /;

=head1
	Do Common Things
=head2 Conventions
	life and instance refer to,respectively, permanent while the $system is running, and 'for $this action'
=cut

sub reset_instance {
	my ( $self ) = @_;
	for ( sort( keys( @{$self->{instance}->{modules}} ) ) ) {
		undef( @{$self->{instance}->{modules}} );
	}
	delete( $self->{instance}->{date} );
}

=head1
	The Lazy Loader
=cut

sub lload {
	my ( $self, $p ) = @_;

	#what else might be needed? :|
	for ( qw/ module / ) {
		die unless $p->{$_};
	}

	#defaults
	my $tag      = $p->{tag}      || 'default';
	my $lifespan = $p->{lifespan} || 'life';

	#create new unless exists already
	unless ( $self->{$lifespan}->{modules}->{$p->{module}}->{$tag} ) {
		die "module loading failed : $! " unless require_module( $p->{module} );
		if ( $p->{initsub} ) {
			$self->{$lifespan}->{modules}->{$p->{module}}->{$tag} = &{$p->{initsub}}( $p );
		} else {
			$self->{$lifespan}->{modules}->{$p->{module}}->{$tag} = "$p->{module}"->new();
		}
	}
	return $self->{$lifespan}->{modules}->{$p->{module}}->{$tag};
}

=head1 Files
	Persisting instance files
=cut

sub ofh_for {
	my ( $self, $path, $p ) = @_;
	die "path not supplied" unless $path;
	unless ( $self->{instance}->{modules}->{"Toolbox::Core"}->{ofhs}->{$path} ) {
		open( $self->{instance}->{modules}->{"Toolbox::Core"}->{ofhs}->{$path}, ">", $path ) or die "Failed to open file : $!";
	}
	$self->{instance}->{modules}->{"Toolbox::Core"}->{ofhs}->{$path};
}

sub close_fh {
	my ( $self, $list ) = @_;

	if ( $list ) {
		for ( @{$list} ) {
			$self->ofh_for( $_ )->close();
		}
	} else {
		for ( sort( keys( %{$self->{instance}->{modules}->{"Toolbox::Core"}->{ofhs}} ) ) ) {
			$self->ofh_for( $_ )->close();
		}
	}
}

1;
