package Toolbox::Time;
use POSIX;
our $VERSION = 'v1.0.2';

##~ DIGEST : 18c38a0e1e4328a578570c05eeff5995

#ABSTRACT: Time Things
use Try::Tiny;
use Moo;

# YYYY:MM:DDTHH:MM:SS
sub timestring {

	POSIX::strftime( "%Y:%m:%dT%H:%M:%S", gmtime() );
}

1;
