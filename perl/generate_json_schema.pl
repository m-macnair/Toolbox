#!/usr/bin/perl
use strict;
use warnings;
use Ryza::CombinedCLI;
use Data::Dumper;
use Text::CSV;
main();

sub main {

    my $c = Ryza::CombinedCLI::array_config(
        [
            [

                qw/ input /
            ]
        ],
    );

    open my $fh, "<:encoding(utf8)", $c->{input} or die "$c->{input}: $!";
    my $last;
    my $structure = {
        type       => 'object',
        properties => {},
    };

    my $csv = Text::CSV->new( { binary => 1 } )   # should set binary attribute.
      or die "Cannot use CSV: " . Text::CSV->error_diag();
    $csv->eol("$/");
    my $offsets = [];
    push( @{$offsets}, $structure );

    # 	push( @{$offsets}, $structure );
    # 	print Dumper($offsets);
    while ( my $row = $csv->getline($fh) ) {
      THISROW: {
            my $offset = 0;
            for my $column ( @{$row} ) {

                if ($column) {
                    last;
                }
                $offset++;
            }
            if ( defined( $offsets->[$offset] ) ) {
                splice( @{$offsets}, $offset + 1 );
            }

            my $name = $row->[ $offset + 0 ];
            next unless $name;
            $name =~ s/^\s+|\s+$//g;
            my $type = $row->[ $offset + 1 ];
            $type =~ s/^\s+|\s+$//g;
            my $desc = $row->[ $offset + 2 ];
            $desc =~ s/^\s+|\s+$//g if $desc;

            $offsets->[$offset]->{properties}->{$name} ||= {};
            my $target = $offsets->[$offset]->{properties}->{$name};

            $target->{type}        = $type;
            $target->{description} = $desc if $desc;
            push( @{$offsets}, $target );

        }
    }
    $csv->eof or $csv->error_diag();
    close $fh;
    use JSON;

    # 	print Dumper($structure);
    # 	print Dumper($offsets);
    my $json = JSON->new()->utf8->canonical(1)->pretty(1);
    print $json->encode($structure);
}

