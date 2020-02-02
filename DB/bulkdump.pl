use strict;
use warnings;
main(@ARGV);

sub main {
    my ( $uname, $pw, $odir ) = @_;
    for my $db (
        qw/
        file_db

        /
      )
    {
        `mysqldump -u $uname -p$pw $db > "$odir/$db.sql"`;
    }
}
