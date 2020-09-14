
#!/usr/bin/perl
use strict;
use warnings;
use lib '/home/m/git/Moo-GenericRole/lib';

package Obj;
use Moo;

with qw/
  Moo::GenericRole::UserAgent
  Moo::GenericRole::JSON
  Moo::GenericRole::CombinedCLI
  Moo::GenericRole::FileSystem
  Moo::GenericRole::FileIO
  /;
use Toolbox::FileIO::CSV;

sub process_list_file {
    my ( $self, $path ) = @_;
    $path ||= $self->cfg->{list_file};
    $self->checkfile($path);
    my $map = {};
    Toolbox::FileIO::CSV::suboncsv(
        sub {
            my $row = shift;
            return 1 unless $row->[0];
            $map->{ $row->[0] }->{hash} = $map->{ $row->[1] };
            return 1;
        },
        $path
    );
    return $map;
}

sub print_map_file {
    my ( $self, $map, $path ) = @_;
    my $csv = Toolbox::FileIO::CSV::getcsv;
    my $ofh = $self->ofh($path);
    use Data::Dumper;

    for my $path ( sort( keys( %{$map} ) ) ) {
        $csv->print( $ofh,
            [ $path, $map->{$path}->{hash}, $map->{$path}->{known} || 0, ] );
    }
    $self->closefhs( [$path] );
}

sub md5_dir {
    my ( $self, $dir ) = @_;
    my $map = {};
    $self->sub_on_files(
        sub {
            my ($path) = @_;
            my $ctx = $self->md5_path($path);
            $map->{$path}->{hash} = $ctx->hexdigest();
            return 1;
        },
        $dir
    );
    return $map;

}

sub md5_path {
    my ( $self, $path ) = @_;
    use Digest::MD5;
    my $ctx = Digest::MD5->new;
    open( my $fh, '<', $path ) or Carp::confess "Can't open [$path]: $!";
    $ctx->addfile($fh);
    return $ctx;
}

1;

package main;
use Toolbox::CombinedCLI;

main();

sub main {
    my $o = Obj->new();
    $o->get_config( [qw/ mode /], [qw/ list_file out_path working_dir/] );

    if ( $o->cfg->{mode} eq 'generate' ) {
        $o->check_cfg( [qw/out_path working_dir/] );
        my $map = $o->md5_dir( $o->cfg->{working_dir} );

        $o->print_map_file( $map, $o->cfg->{out_path} );
        print "$/done!$/";
        exit;
    }
    else {
        die "unknown action";
    }

    my $map  = $o->process_list_file();
    my $keys = keys(%$map);

    use Data::Dumper;
    print Dumper(
        $o->post_retrieve_json(
            'http://localhost/apitrial.pl',
            {
                'keys' => $keys
            }
        )
    );

}

1;
