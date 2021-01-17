use strict;
use warnings;
use JSON;
use File::Slurp;
main( @ARGV );

sub main {
	my ( $infile, $table_file ) = @_;
	my $json = JSON->new();
	$json->canonical( 1 )->pretty( 1 );
	my $json_string = File::Slurp::slurp( $infile );
	my @tables      = sort( split( $/, File::Slurp::slurp( $table_file ) ) );

	# 	warn $json_string;
	my $conf = $json->decode( $json_string );

	for my $this_db ( @tables ) {
		$this_db =~ s/[\W]*//g;
		next unless $this_db;

		my $def = {%{$conf}};
		$def->{db}   = $this_db;
		$def->{path} = "./$this_db/" if exists( $def->{path} );
		open( my $fh, '>:raw', "./$this_db.json" ) or die $!;
		print $fh $json->encode( $def );
		close( $fh );
	}
}
