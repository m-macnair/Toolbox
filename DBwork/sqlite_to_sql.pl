use strict;
use warnings;
use Ryza::CombinedCLI;
use Data::Dumper;
use DBI;
main(@ARGV);

sub main {
    #
    my $c = Ryza::CombinedCLI::array_config( [qw/sqlfile  dsn user pass /],
        [qw/except /] );

    my $sqlite_h = DBI->connect(
        "dbi:SQLite:$c->{sqlfile}",
        undef, undef,
        {
            AutoCommit                 => 1,
            RaiseError                 => 1,
            sqlite_see_if_its_a_number => 1,
        }
    );

    #first time finding out about this table
    my $get_tables_sth = $sqlite_h->prepare("select * from SQLITE_MASTER");
    $get_tables_sth->execute();

    my $osql_h = DBI->connect(
        $c->{dsn},
        $c->{user},
        $c->{pass},
        {
            AutoCommit                 => 0,
            RaiseError                 => 1,
            sqlite_see_if_its_a_number => 1,
        }
    ) or die $!;
    my $counter = 0;
    my $limit   = 100;
    my $persist = { dbh => $osql_h };
    for ( split( ',', $c->{except} ) ) {
        $persist->{skips}->{$_} = 1;
    }

    while ( my $table_row = $get_tables_sth->fetchrow_hashref() ) {
        if ( $persist->{skips}->{ $table_row->{name} } ) {
            print "Skipping $table_row->{name}$/";
            next;
        }
        print "Processing $table_row->{name}$/";
        my $table_content_sth =
          $sqlite_h->prepare("select * from $table_row->{name}");

        $table_content_sth->execute();

        while ( my $data_row = $table_content_sth->fetchrow_hashref ) {

            my ( $sth, $keys ) =
              get_insert_sth( $persist, $table_row->{name}, $data_row );
            my @values = @{$data_row}{ @{$keys} };

            $sth->execute(@values);
            if ( $counter >= $limit ) {
                $counter = 0;
                $osql_h->commit();
            }
            $counter++;
        }

    }
    $osql_h->commit();

}

sub get_insert_sth {
    my ( $persist, $name, $row ) = @_;

    $persist->{$name} ||= {};
    unless ( $persist->{$name}->{sth} ) {

        # 		warn Dumper( $row );
        my @keys      = sort( keys( %{$row} ) );
        my $keystring = join( ",", @keys );
        my $phstring  = '' . ( '?,' x @keys );
        $phstring = substr( $phstring, 0, -1 );

        # 		warn $phstring;
        my $qstring = "insert into $name ( $keystring ) values ($phstring)";

        $persist->{$name}->{sth} = $persist->{dbh}->prepare($qstring);
        $persist->{$name}->{'keys'} = \@keys;
    }
    return ( $persist->{$name}->{sth}, $persist->{$name}->{'keys'} );
}
