use strict;
use warnings;

package Toolbox::Class::JSDispatch;
our $VERSION = 'v1.0.1';

##~ DIGEST : a09c01717e3983becf740c13e76b3ae6

# init
sub new {

	my ( $proto, $conf ) = @_;
	$conf ||= {};
	my $class = ref( $proto ) || $proto;
	my $self = bless {}, $class;

	$self->{keymap} = $self->_key_to_code();

	$self->{js} = {};

	#all of this is wrong and should come from separate files, but for now~
	WRONG: {
		$self->{js}->{keydownaction} = qq#
			document.onkeydown = function(evt) {
					evt = evt || window.event;
					/* stack o' redirects */
					%s
			};
		#;

		$self->{js}->{'outboundrequest'} = qq#
			function karequest(url) { 
				var xhr = new XMLHttpRequest();
				xhr.open("GET", url, true);

				xhr.onload = function (e) {
					if (xhr.readyState === 4) {
						if (xhr.status === 200) {
							var res = xhr.responseText;
							$conf->{extra_outboundrequest_success}
						} else {
							console.error(xhr.statusText);
						}
					}
				};
				xhr.onerror = function (e) {
					console.error(xhr.statusText);
				};
				xhr.send(null);
				return xhr;
			}
		#;

		$self->{js}->{'if'} = qq#
			if (evt.keyCode == %s) {
				%s
			}
		#;
	}

	return $self;
}

sub _key_to_code {

	return {
		'0' => 48,
		'1' => 49,
		'2' => 50,
		'3' => 51,
		'4' => 52,
		'5' => 53,
		'6' => 54,
		'7' => 55,
		'8' => 56,
		'9' => 57,
		'a' => 65,
		'b' => 66,
		'c' => 67,
		'd' => 68,
		'e' => 69,
		'f' => 70,
		'g' => 71,
		'h' => 72,
		'i' => 73,
		'j' => 74,
		'k' => 75,
		'l' => 76,
		'm' => 77,
		'n' => 78,
		'o' => 79,
		'p' => 80,
		'q' => 81,
		'r' => 82,
		's' => 83,
		't' => 84,
		'u' => 85,
		'v' => 86,
		'w' => 87,
		'x' => 88,
		'y' => 89,
		'z' => 90
	};
}

sub generateinterface {
	my ( $self, $conf ) = @_;

	my $return;
	$return .= $self->{js}->{outboundrequest};
	$return .= $self->jsformap( $conf->{urlmap}, $conf->{jsformapconf} );

	return $return; #return!
}

sub jsformap {
	my ( $self, $map, $conf ) = @_;
	$conf ||= {};

	my $ifstack;
	my $morethanone;
	for my $key ( sort( keys( %{$map} ) ) ) {
		if ( $morethanone ) {
			$ifstack .= ' else ';
		}
		my $url =
		  $ifstack .= sprintf( $self->{js}->{'if'}, $self->codeforkey( $key ), qq|var xhr = karequest("$map->{$key}");$conf->{extrafunction}| );
		$morethanone = 1;
	}

	return sprintf( $self->{js}->{keydownaction}, $ifstack );
}

sub codeforkey {
	my ( $self, $key ) = @_;
	my $keycode;
	unless ( $keycode = $self->{keymap}->{lc( $key )} ) {
		die "requested key [$key] does not map to a code";
	}
	return $keycode;
}

