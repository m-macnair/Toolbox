use strict;

package Toolbox::Common;

sub findfilesub {
    my ( $dir, $sub ) = @_;
    die "[$dir] is not a directory" unless ( -d $dir );
    require File::Find;

    File::Find::find(
        {
            wanted => sub {
                return if -d ($File::Find::name);
                return if -l ($File::Find::name);
                &$sub($File::Find::name);
            },
            no_chdir => 1,
            follow   => 0,
        },
        $dir
    );
}

sub orcache {
    my ( $cache, $key, $value, $sub ) = @_;
    $cache = {} unless $cache;
    unless ( $cache->{$key}->{$value} ) {
        $cache->{$key}->{$value} = &$sub($value);
    }
    return $cache->{$key}->{$value};
}

sub transactioncounter {
    my ( $dbh, $counter, $limit ) = @_;
    $counter++;
    if ( $counter >= $limit ) {
        $dbh->commit();
        $counter = 0;
    }
}

sub md5binfile {
    my ($file) = @_;

    require Digest::MD5;
    open( my $fh, '<', $file ) or return { fail => "Can't open [$file]: $!" };
    binmode($fh);
    my $md5 = Digest::MD5->new;
    while (<$fh>) {
        $md5->add($_);
    }
    close($fh);
    return { pass => $md5->digest, md5o => $md5 };
}

sub md5hexfile {
    my ($file) = @_;
    my $result = md5binfile($file);
    return $result unless $result->{pass};
    return { pass => $result->{pass}->hexdigest(), m5o => $result->{pass} };
}

sub required {
    my ( $href, $values ) = @_;
    for (@$values) {
        unless ( exists( $href->{$_} ) ) {
            return { fail => "Missing value $_" };
        }
    }
    return { pass => 1 };
}

sub suboncsv {
    my ( $file, $sub, $csvopt ) = @_;
    my $fh = $csvopt->{fh};
    require Text::CSV;

    my $csv = Text::CSV->new( { binary => 1 } )   # should set binary attribute.
      or die "Cannot use CSV: " . Text::CSV->error_diag();
    $csv->eol($/);
    unless ($fh) {
        open $fh, "<:encoding(utf8)", $file or die "suboncsv failed : [$!] ";
    }
    my $rowcount = 1;
    my $continue = 1;
    while ( my $row = $csv->getline($fh) ) {
        &$sub( $row, $rowcount, \$continue );
        last unless $continue;
        $rowcount++;
    }
    $csv->eof or $csv->error_diag();
    close $fh;
}

1;
