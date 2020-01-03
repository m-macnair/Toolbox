use strict;
use warnings;

package Toolbox::Core::Lib::CSV;

sub hreftocsv {
    my ( $self, $filename, $href, $conf ) = @_;

    my $columns =
      $self->{instance}->{data}->{'Toolbox::CSV'}->{$filename}->{columns};

    unless ($columns) {
        if ( $conf->{columns} ) {
            $columns = $conf->{columns};
        }
        else {
            $columns = [ sort( keys( %{$href} ) ) ];
        }
        $self->csv->print( $self->ofh_for($filename), $columns )
          unless $conf->{noheadings};
        $self->{instance}->{data}->{'Toolbox::CSV'}->{$filename}->{columns} =
          $columns;

    }

    #for when we just wanted to set the columns
    if ($href) {

        #there's a sharper way to do this
        my $row;
        for ( @{$columns} ) {
            push( @{$row}, $href->{$_} );
        }
        $self->csv->print( $self->ofh_for($filename), $row );
    }
}

sub suboncsv {

    my ( $self, $path, $sub ) = @_;

    die "[$path] not found" unless ( -e $path );
    die "sub isn't a code reference" unless ( ref($sub) eq 'CODE' );

    open( my $ifh, "<:encoding(UTF-8)", $path )
      or die "Failed to open [$path] : $!";

    while ( my $colref = $self->csv->getline($ifh) ) {
        if ( index( $colref->[0], '#' ) == 0 ) {
            next;
        }
        &$sub($colref);
    }

    close($ifh) or die "Failed to close [$path] : $!";

}

sub csv {
    my ( $self, $p ) = @_;
    $p ||= {};
    return $self->lload(
        {
            initsub =>
              sub { "Text::CSV"->new( { binary => 1, eol => "\n" } ); },
            %{$p},
            module => "Text::CSV"
        }
    );
}

1;
