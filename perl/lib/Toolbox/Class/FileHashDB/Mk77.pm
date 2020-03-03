package Toolbox::Class::FileHashDB::Mk77;
our $VERSION = '0.04';

##~ DIGEST : ada7298d5c260c54af1006e3a486cf32
use Moo;
with(
	qw/
	  Toolbox::Moo::Role::DB
	  Toolbox::Moo::Role::Debug
	  /
);
use Toolbox::FileSystem;
use Try::Tiny;

use DBI; #SQL_VARCHAR
ACCESSORS: {

	#creating/reusing the sqlite file
	DBFILE: {
		has initdb => ( is => 'rw', );
		has dbfile => (
			is      => 'rw',
			lazy    => 1,
			default => sub { $_[0]->initdb( 1 ); return "./" . time . ".sqlite" }
		);
	}

	#variable for when on windows
	has directory_separator => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return '/' }
	);

	STHS: {

		for my $pair (

			#FILE
			[ 'sth_storefile', "insert into file_list (name,dir_id,ext_id,size) values (?,?,?,?)" ],
			[ 'sth_knownfile', "select id from file_list where name = ? and dir_id = ? and ext_id = ?" ],
			[ 'sth_setmd5',    "update file_list set md5 = ? where id = ?" ],

			#DIR
			[ 'sth_storedir', "insert into dir_list (name) values (?)" ],
			[ 'sth_dir_id',   "select id from dir_list where name = ?" ],

			#EXT
			[ 'sth_storeext', "insert into ext_list (name) values (?)" ],
			[ 'sth_ext_id',   "select id from ext_list where name = ?" ],

			#MISC
			[ 'sth_lastinsert', "select last_insert_rowid() as id" ],

		  )
		{
			has $pair->[0] => (
				is      => 'rw',
				lazy    => 1,
				default => sub { $_[0]->dbh->prepare( $pair->[1] ) }
			);
		}
	}

}

sub BUILD {
	my ( $self, $conf ) = @_;

	$self->_set_dbh(
		'dbi:SQLite:' . $self->dbfile,
		undef, undef,
		{
			AutoCommit                 => 0,
			RaiseError                 => 1,
			sqlite_see_if_its_a_number => 1,
		}
	);

	if ( $self->initdb() ) {
		$self->_initblankdb( $self->dbh );
	}
}

#
#
#
# =head2 Critical Paths
# 	delete duplicate files in the least deep folders
# =cut
#
sub criticalpath1 {
	my ( $self, $dir ) = @_;

	$self->loaddirectory( $dir );
	$self->md5all();
	$self->initdirweight();
	$self->commithard();

}

sub criticalpath2 {
	my ( $self, $dir ) = @_;
	$self->criticalpath1( $dir );
	$self->setonetrue();
	$self->commithard();
	$self->setcheckedanddelete();
}

sub criticalpath3 {
	my ( $self, $dir ) = @_;
	$self->criticalpath2( $dir );
	$self->dodeletes();
}

# =head2 PRIMARY SUBS
#
# =cut
#
sub _initblankdb {
	my ( $self, $dbh ) = @_;
	die "no dbh" unless $dbh;
	$dbh->do( "
			CREATE TABLE db_attributes (
				attribute TEXT PRIMARY KEY ,
				value TEXT
			);#fails silently when table already exists
   " ) or die $DBI::errstr;
	$dbh->do( "
			CREATE TABLE file_list (
				id INTEGER PRIMARY KEY ,
				name TEXT,
				dir_id INTEGER ,
				ext_id INTEGER ,
				size INTEGER,
				md5 BLOB,
				one_true BOOL ,
				one_true_checked BOOL,
				todelete BOOL,
				deleted BOOL
				
			);
		" ) or die $DBI::errstr;
	for ( qw/md5 one_true one_true_checked todelete deleted/ ) {
		$dbh->do( "
			CREATE index $_\_index ON file_list($_);
		" ) or die $DBI::errstr;
	}

	$dbh->do( "
			CREATE TABLE dir_list (
				id INTEGER PRIMARY KEY ,
				name TEXT,
				weight INTEGER
			);
		" ) or die $DBI::errstr;
	for ( qw/name weight/ ) {
		$dbh->do( "
			CREATE index dir_list_$_\_index ON dir_list($_);
		" ) or die $DBI::errstr;
	}

	$dbh->do( "
			CREATE TABLE ext_list (
				id INTEGER PRIMARY KEY ,
				name TEXT
			);
		" ) or die $DBI::errstr;
	for ( qw/name weight/ ) {
		$dbh->do( "
			CREATE index extlist_$_\_index ON dir_list($_);
		" ) or die $DBI::errstr;
	}
	$dbh->commit();
}

#

=head3 loaddirectory
	turn a perfectly good directory structure into sqlite
=cut

sub loaddirectory {
	my ( $self, $dir ) = @_;
	Toolbox::FileSystem::subonfiles(
		sub {
			my ( $path ) = @_;
			$self->storepath( $path );
			return;
		},
		$dir
	);
	$self->commithard();
}

# =head2 SECONDARY SUBS
# =head3 storepath
# 	record a single file path in sqlite
# =cut
#
#
#
#
sub storepath {
	my ( $self, $fullpath ) = @_;
	unless ( -e $fullpath ) {
		warn "[$fullpath] is not a path";
		return;
	}
	$self->debug_msg( "storing [$fullpath]" );
	require File::Basename;
	my ( $name, $path, $suffix ) = File::Basename::fileparse( $fullpath, qr/\.[^.]*/ );
	my $dirid    = $self->getdirid( $path );
	my $extid    = $self->getextid( $suffix );
	my $size     = -s $path;
	my $storesth = $self->sth_storefile();

	if ( $self->checkifknown( $name, $dirid, $extid ) ) {
		$self->debug_msg( "would have duplicated a known file [$fullpath]" );
	} else {

		#file names may have leading 0s which at this point will turn 011 to 11
		$storesth->bind_param( 1, $name, {TYPE => DBI::SQL_VARCHAR} );
		$storesth->bind_param( 2, $dirid );
		$storesth->bind_param( 3, $extid );
		$storesth->bind_param( 4, $size );
		$storesth->execute();
		$self->commitmaybe();
	}
}

=head2 getdirid
	Retrieve from the cache or directly
=cut

#
sub getdirid {
	my ( $self, $dir ) = @_;
	$self->get_x_id( 'dir', $dir );
}

sub getextid {
	my ( $self, $dir ) = @_;
	$self->get_x_id( 'ext', $dir );
}

sub get_x_id {
	my ( $self, $x, $value ) = @_;
	my $getsth = "sth_$x\_id";
	$self->$getsth->execute( $value );
	my $row;
	unless ( $row = $self->$getsth->fetchrow_arrayref() ) {
		my $storesth = "sth_store$x";
		$self->$storesth->execute( $value );
		$self->$getsth->execute( $value );
		$row = $self->$getsth->fetchrow_arrayref();
	}
	return $row->[0];

}

sub checkifknown {
	my ( $self, $name, $dirid, $extid ) = @_;
	$self->sth_knownfile->execute( $name, $dirid, $extid );
	if ( $self->sth_knownfile->fetchrow_arrayref() ) {
		return 1;
	} else {
		return 0;
	}
}

sub getlastinsert {
	my ( $self ) = @_;

	$self->sth_lastinsert->execute();
	if ( my $row = $self->sth_lastinsert->fetchrow_arrayref() ) {
		return $row->[0];
	} else {
		return 0;
	}
}

# =head1 processing
#
# =cut
#
sub md5all {
	my ( $self ) = @_;
	my $fetchsth = $self->dbh->prepare( "
				select 
					f.id as id,
					d.name as dir,
					f.name as file ,
					e.name as ext
				from 
					file_list f 
					join dir_list d 
						on f.dir_id = d.id
					join ext_list e 
						on f.ext_id = e.id
				where f.md5 is null
		" );
	$fetchsth->execute();
	while ( my $row = $fetchsth->fetchrow_hashref() ) {
		my $md5 = $self->md5path( "$row->{dir}/$row->{file}$row->{ext}" );
		$self->setidmd5( $row->{id}, $md5 );
	}
	$self->commithard();

}

#
sub md5path {
	my ( $self, $path ) = @_;
	use Digest::MD5;
	my $ctx = Digest::MD5->new;
	open( my $fh, '<', $path ) or die "Can't open [$path]: $!";
	$ctx->addfile( $fh );
	return $ctx->digest;
}

#
sub setidmd5 {
	my ( $self, $id, $md5 ) = @_;
	$self->sth_setmd5->execute( $md5, $id );
	$self->commitmaybe();
}

#
sub initdirweight {
	my ( $self )     = @_;
	my $dirliststh   = $self->dbh->prepare( "select * from dir_list order by name asc" );
	my $setweightsth = $self->dbh->prepare( "update dir_list set weight = ? where id = ?" );
	$dirliststh->execute();
	while ( my $row = $dirliststh->fetchrow_hashref() ) {
		my @slashes = split( $self->directory_separator, $row->{name} );
		$setweightsth->execute( scalar( @slashes ), $row->{id} );
		$self->commitmaybe();
	}
	$self->commithard();
}

#
sub setonetrue {
	my ( $self ) = @_;
	my $md5ssth = $self->dbh->prepare(
		q/
		select distinct(md5) as md5 from file_list
	/
	);
	$md5ssth->execute();

	my $filesforsth = $self->dbh->prepare(
		q/
			select f.id
			from file_list f
			join dir_list d 
				on f.dir_id = d.id
			where md5 = ?
			order by d.weight desc , d.name desc , length(f.name) desc
	/
	);

	my $thisfilesth = $self->dbh->prepare(
		q/
		update file_list set one_true = 1 where id = ?
	/
	);

	my $thosefilesth = $self->dbh->prepare(
		q/
		update file_list set one_true_checked = 1 where md5 = ?
	/
	);
	while ( my $md5row = $md5ssth->fetchrow_hashref ) {
		$filesforsth->execute( $md5row->{md5} );
		my $onetruerow = $filesforsth->fetchrow_hashref();

		#this can't not be set unless the db was interfered with at some point
		if ( $self->debug() ) {

			#expensive action if not in debug mode
			my $md5_string = $self->debug_msg( "Setting $onetruerow->{id} as one true file for [<unknown digest>]" );
		}

		$thisfilesth->execute( $onetruerow->{id} );
		$thosefilesth->execute( $md5row->{md5} );
		$self->commitmaybe();
	}

	$self->commithard();
}

#
sub setcheckedanddelete {
	my ( $self ) = @_;
	my $truemd5sth = $self->dbh->prepare( "
		select md5, id from file_list where one_true = 1 and md5 is not null;
	" );

	my $checkedmd5sth = $self->dbh->prepare( "
		update file_list 
		set 
			one_true_checked = 1,
			todelete = 1
		where
			md5 = ?
			and id != ?
	" );
	$truemd5sth->execute();
	while ( my $truerow = $truemd5sth->fetchrow_hashref() ) {
		$checkedmd5sth->execute( $truerow->{md5}, $truerow->{id} );
		$self->commitmaybe();
	}
	$self->commithard();
}

#
sub dodeletes {
	my ( $self ) = @_;

	my $fetchsth = $self->dbh->prepare( "
		select
			f.id as id,
			d.name as dir,
			f.name as file ,
			e.name as ext
		from
			file_list f 
			join dir_list d 
				on f.dir_id = d.id
			join ext_list e 
				on f.ext_id = e.id
			where todelete = 1 
			and deleted is null
	" );
	my $deletedsth = $self->dbh->prepare( "
			update file_list set deleted = 1 where id = ? ;
	" );
	$fetchsth->execute();
	while ( my $row = $fetchsth->fetchrow_hashref() ) {
		my $path = "$row->{dir}/$row->{file}$row->{ext}";
		if ( -f $path ) {
			if ( unlink( $path ) ) {
				$self->debug_msg( "deleted file [$path]" );
				$deletedsth->execute( $row->{id} );
				$self->commitmaybe();
			} else {
				die "failed to delete file [$path]: $!";
			}
		} else {
			if ( -e $path ) {
				die "attempted to delete non-file path [$path]";
			} else {
				$self->debug_msg( "attempted to delete non-existant path [$path]" );
			}
		}
	}
	$self->commithard();
}

1;
