package Toolbox::SqlAbstract::Cached;

use Moo;
our $VERSION = 'v1.0.2';

##~ DIGEST : 262a6717d833b03077d97f3212cf9a40
extends 'Toolbox::SqlAbstract';
ACCESSORS: {
    has _stmnt_cache => (
        is      => 'rw',
        lazy    => 1,
        default => sub { return {} };
    );
}

=head3 _get_prepared
	for to be more complex at some point probably
=cut

sub _get_prepared {
    my ( $self, $id ) = @_;
    my $return = $self->_stmnt_cache->{$id};
    unless ($return) {
        my $sth = $self->dbh->prepare("$id")
          or die "failed to prepare statement :/";
        $return = $self->_stmnt_cache->{$id} = $sth;
    }
    return $return;    #return
}

sub _shared_query {
    my ( $self, $Q, $P ) = @_;
    $P ||= [];
    my $sth = $self->_get_prepared($Q);
    $sth->execute( $sth, @{$P} );
    return $sth;
}
1;
