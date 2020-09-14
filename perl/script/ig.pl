use strict;
use warnings;
our $VERSION = 'v1.0.13';

##~ DIGEST : bd5a62ec1de39b21712423d99edadaf1

#IG trading platform API trial

package IGAPI;

use Moo;
with qw/
  Moo::Role::UserAgent
  Moo::Role::JSON
  Moo::Role::FileSystem
  Moo::Role::FileIO
  Moo::Role::UUID
  /;
use Time::HiRes qw/gettimeofday/;
use Data::Dumper;
use JSON;
use Carp qw/confess /;

ACCESSORS: {

  OPERATION: {
        has rooturl       => ( is => 'rw', );
        has mute          => ( is => 'rw' );
        has accountstatus => ( is => 'rw' );
        has currency      => ( is => 'ro', default => sub { 'GBP' } )
          ;    # should never change
    }
  AUTH: {
        has user             => ( is => 'rw', );
        has pass             => ( is => 'rw', );
        has key              => ( is => 'rw', );
        has cst              => ( is => 'rw', );
        has cstage           => ( is => 'rw', );
        has securitytoken    => ( is => 'rw', );
        has securitytokenage => ( is => 'rw', );
    }
  AUDIT: {
        has auditroot => ( is => 'rw' );
        has auditdir  => (
            is => 'ro'
            ,   # this should never change after creation surely? :thinkingface:
            lazy => 1,

#straight copy Toolbox::FileSystem::buildtmpdirpath... which lead to it being refactord :dappershark:
            default => sub {

                my ($self) = @_;
                my $path = $self->buildtimepath( $self->auditroot() );
                $self->mkpath($path);
                return $path;
            }

        );

        has logfilepath => (
            is      => 'rw',
            lazy    => 1,
            default => sub {
                my ($self) = @_;
                return $self->auditdir() . '/activity.log';
            }
        );
        has logfilehandle => (
            is      => 'rw',
            lazy    => 1,
            default => sub {
                my ($self) = @_;
                open( my $fh, ">:encoding(UTF-8)", $self->logfilepath() )
                  or confess("Failed to open logfile! : $!");

                #Cargo Cultin'
                my $h = select($fh);
                $| = 1;
                select($h);

            }

        );
    }

}    #/ACCESSORS

sub auditedrequest {
    my ( $self, $p, $q, $headers, ) = @_;
    $q ||= {};

    #this *might* be persistable
    my $ua = $self->lwpuseragent();
    $ua->timeout( $self->defaulttimeout );

    #build the request
    require HTTP::Request;
    my $req = HTTP::Request->new( $p->{type}, $p->{url} );

    #cargo cultin'
    $req->header(
        'Version'      => $p->{version} || 2,
        'X-IG-API-KEY' => $self->key(),
        'Content-Type' => 'application/json; charset=UTF-8',
        'Accept'       => 'application/json; charset=UTF-8',
    );

    for my $header ( keys( %{$headers} ) ) {
        $req->header( $header => $headers->{$header} );
    }
    if ( %{$q} ) {
        $req->content( $self->json->encode($q) );
    }

    #log what we're about to do
  LOGREQ: {
        my ( $s, $usec ) = gettimeofday();

        my $requestfh =
          $self->ofh( $self->auditdir() . "/$s\_$usec\_request.pm" );
        print $requestfh Dumper($req);
        close($requestfh);
    }

    #hcf when/where necessary
    my $result;
  LOGRESPONSE: {
        my ( $s, $usec ) = gettimeofday();
        my $responsefh =
          $self->ofh( $self->auditdir() . "/$s\_$usec\_response.pm" );
        $result = $ua->request($req);
        print $responsefh Dumper($result);
        close($responsefh);
    }
    if ( $result->{_rc} != 200 ) {
        if ( $result->{_content} ) {
            $self->log( $result->{_content} );
        }
        $self->log("Request failed - check audit for cause");
        exit;
    }

    return ($result);

}

=head3 getencryptionkey
	used to mask the password apparently
=cut

sub getencryptionkey {
    my ($self) = @_;
    my $res = $self->auditedrequest(
        {
            url  => $self->rooturl() . '/session/encryptionKey',
            type => 'GET'
        }
    );
    my $decodedres = $self->json->decode( $res->{_content} );
    die Dumper($decodedres);
}

sub login {
    my ($self) = @_;
    $self->log("Starting new session");

    # 	my $key = $self->getencryptionkey();

    # 	$self->pass($self->encrypt($self->pass()));
    my $res = $self->auditedrequest(
        {
            url  => $self->rooturl() . '/session',
            type => 'POST'
        },
        {
            identifier        => $self->user(),
            encryptedPassword => JSON::false,
            password          => $self->pass(),
        }
    );

    $self->accountstatus( $self->json->decode( $res->{_content} ) );

    $self->securitytoken( $res->{_headers}->{'x-security-token'} );
    $self->log(
        "Got security token value [$res->{_headers}->{'x-security-token'}]");
    $self->cst( $res->{_headers}->{cst} );
    $self->log("Got cst value [$res->{_headers}->{cst}]");
    my $now = time;
    $self->cstage($now);
    $self->securitytokenage($now);

}

=head3 getepic
	get the IG trading platform unique value for a $something
=cut

sub getepics {
    my ( $self, $search ) = @_;

    my $res = $self->auditedrequest(
        {
            url     => $self->rooturl() . "/markets?searchTerm=$search",
            type    => 'GET',
            version => 1,
        },
        undef,
        $self->authheaders()
    );
    print Dumper($res);

}

sub getepicdetail {
    my ( $self, $epiccode ) = @_;

    my $res = $self->auditedrequest(
        {
            url     => $self->rooturl() . "/markets/$epiccode",
            type    => 'GET',
            version => 1,
        },
        undef,
        $self->authheaders()
    );
    print Dumper($res);
}

sub snakeuuid {
    my ($self) = @_;
    my $uuid = substr( $self->getuuid(), undef, 29 );

    $uuid =~ s|-|_|g;
    return $uuid;
}

sub order {
    my ( $self, $p ) = @_;

    #default-able
    my $orderbody = {
        currencyCode  => $p->{currency}      || $self->currency(),
        dealReference => $p->{dealReference} || $self->snakeuuid(),
        timeInForce =>
          ( $p->{timeInForce} ? $p->{timeInForce} : 'GOOD_TILL_CANCELLED' ),
        type => ( $p->{type} && $p->{type} eq 'STOP' ) ? 'STOP' : 'LIMIT'
    };

  REQUIRED: {
        for my $required (
            qw/
            direction
            epic
            size
            level
            expiry
            /
          )
        {
            confess("$required not provided") unless $p->{$required};
        }

        $orderbody->{direction} = uc( $p->{direction} );

        #always uppercase - IG's proprietary identifiers
        $orderbody->{epic} = $p->{epic};

        #how big an order
        $orderbody->{size} = $p->{size};

        #when to carry out the order (?)
        $orderbody->{level} = $p->{level};

        #when expires - not sure why this is here
        $orderbody->{expiry} = $p->{expiry};

        #when expires - not sure why this is here

    }

    #BOOLEAN
    for (
        qw/
        forceOpen
        guaranteedStop
        /
      )
    {
        $orderbody->{$_} = $p->{$_} ? JSON::true : JSON::false;
    }

    #optional - but stopDistance is required ;\
    for (
        qw/
        goodTillDate
        limitDistance
        stopDistance
        stopLevel
        limitLevel

        /
      )
    {
        $orderbody->{$_} = $p->{$_};
    }

  DUMPSTRUCTURE: {
        $self->log("Creating order structure dump");
        my ( $s, $usec ) = gettimeofday();
        my $ofh =
          $self->ofh( $self->auditdir() . "/$s\_$usec\_order_structure.pm" );
        print $ofh Dumper($orderbody);
        close($ofh);
    }

    $self->auditedrequest(
        {
            url  => $self->rooturl() . '/workingorders/otc',
            type => 'POST',
        },
        $orderbody,
        $self->authheaders()
    );

}

sub listorders {
    my ($self) = @_;
    $self->auditedrequest(
        {
            url  => $self->rooturl() . '/workingorders',
            type => 'GET',
        },
        undef,
        $self->authheaders()
    );

}

=head3 authheaders
	return the current correct auth headers or HCF
=cut

sub authheaders {
    my ($self) = @_;
    my $maxold = ( time - 57 );
    if ( $self->cstage() <= $maxold ) {
        $self->logexit('CST is too old');
    }
    if ( $self->securitytokenage() <= $maxold ) {
        $self->logexit('Security token is too old');
    }
    return {
        'x-security-token' => $self->securitytoken(),
        cst                => $self->cst()
    };

}

# TODO actually do something
sub encrypt {
    my ( $self, $pass ) = @_;
    return '';

}

sub log {
    my ( $self, $msg ) = @_;

    #not happy with this ;\
    my ( $s, $usec ) = gettimeofday();
    my $fh = $self->logfilehandle;
    if ( $self->mute() ) {
        print $fh "[$s\_$usec]$msg$/";
    }
    else {
        my $msg = "[$s\_$usec]$msg$/";
        print $fh $msg;
        print $msg;
    }

}

sub logquit {
    my ( $self, $msg ) = @_;
    $self->log($msg);
    exit;
}

1;

package main;
use Toolbox::CombinedCLI;
main();

sub main {
    my $conf = Toolbox::CombinedCLI::get_config(
        [
            qw/
              user
              pass
              rooturl
              key
              auditroot
              /
        ]
    );
    my $self = IGAPI->new($conf);
    $self->login();

    # 	$self->getepic( 'US 500' );
    # 	$self->getepicdetail('IX.D.SPTRD.DAILY.IP');

    $self->order(
        {
            direction => 'SELL',
            epic      => 'AA.D.FLT.DAILY.IP',
            size      => '-0.01',
            level     => '1613.00',
            "expiry"  => "DFB",

            # 		forceOpen => 1,

            limitDistance => 1,
            stopDistance  => 5,

        }
    );

    # 	$self->listorders();

    $self->log('finished');
}

=head1 LICENSE


Copyright 2020 M.Macnair

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
