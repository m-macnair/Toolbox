package Toolbox::Time;
use POSIX;
our $VERSION = 'v1.0.3';

##~ DIGEST : 2c51795bf8a3d8a096985d51236062e1

#ABSTRACT: Time Things
use Try::Tiny;
use Moo;

# YYYY:MM:DDTHH:MM:SS
sub timestring {

    POSIX::strftime( "%Y:%m:%dT%H:%M:%S", gmtime() );
}

1;
