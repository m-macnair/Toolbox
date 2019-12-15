use strict;

package Toolbox::FileManifest::Mk1;
use base "Toolbox::FileManifest";
require Toolbox::Common;
use DBI; #SQL_VARCHAR

sub init {
	my ( $self, $conf ) = @_;

	$self->configure(
		$conf,
		[
			qw/
			  dbfile
			  transactionlimit
			  initdb
			  dirsep
			  debug
			  /
		]
	);

	$self->defaults(
		{
			transactionlimit => 1000,
			dirsep           => "/",
		}
	);

	unless ( $self->{dbfile} ) {
		$self->{dbfile} = "./" . time . ".sqlite";
		$self->{initdb} = 1;
	}

	$self->{DBH} = DBI->connect(
		"dbi:SQLite:$self->{dbfile}",
		undef, undef,
		{
			AutoCommit                 => 0,
			RaiseError                 => 1,
			sqlite_see_if_its_a_number => 1,
		}
	) or die "Failed to connect to $self->{dbfile} : $DBI::errstr";

	if ( $self->{initdb} ) {
		$self->initblankdb( $self->{DBH} );
	}

	return {pass => 1};
}

=head1 Critical Paths
	delete duplicate files in the least deep folders
=cut

sub criticalpath1 {
	my ( $self, $dir ) = @_;

	$self->loaddirectory( $dir );
	$self->md5all();
	$self->initdirweight();
	$self->setonetrue();
	$self->setcheckedanddelete();
}

sub commit {
	my ( $self ) = @_;
	Toolbox::Common::transactioncounter( $self->{DBH}, $self->{transactioncounter}, $self->{transactionlimit} );
}

sub freshcommit {
	my ( $self ) = @_;
	$self->{DBH}->commit();
	$self->{transactioncounter} = 0;
}

sub initblankdb {
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
			CREATE index $_\index ON file_list($_);
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
			CREATE index dir_list$_\index ON dir_list($_);
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
			CREATE index extlist$_\index ON dir_list($_);
		" ) or die $DBI::errstr;
	}
}

sub loaddirectory {
	my ( $self, $dir ) = @_;
	Toolbox::Common::findfilesub(
		$dir,
		sub {
			my ( $path ) = @_;
			$self->storepath( $path );
		}
	);
	$self->freshcommit();
}

sub storepath {
	my ( $self, $fullpath ) = @_;
	unless ( -e $fullpath ) {
		warn "[$fullpath] is not a path";
		return;
	}
	print "storing [$fullpath] $/" if $ENV{debug} || $self->{debug};
	require File::Basename;
	my ( $name, $path, $suffix ) = File::Basename::fileparse( $fullpath, qr/\.[^.]*/ );
	my $dirid    = $self->getdirid( $path );
	my $extid    = $self->getextid( $suffix );
	my $size     = -s $path;
	my $storesth = $self->_storefilesth();

	if ( $self->checkifknown( $name, $dirid, $extid ) ) {
		warn "would have duplicated a known file [$fullpath]" if $ENV{debug} || $self->{debug};
	} else {

		#file names may have leading 0s which at this point will turn 011 to 11
		$storesth->bind_param( 1, $name, {TYPE => DBI::SQL_VARCHAR} );
		$storesth->bind_param( 2, $dirid );
		$storesth->bind_param( 3, $extid );
		$storesth->bind_param( 4, $size );
		$storesth->execute();
		$self->commit();
	}
}

=head2 getdirid
	Retrieve from the cache or directly
=cut

sub getdirid {
	my ( $self, $dir ) = @_;
	$self->{dircache} = {} unless $self->{dircache};
	return Toolbox::Common::orcache(
		$self->{dircache},
		'dir', $dir,
		sub {
			my ( $thisdir ) = @_;
			return $self->_finddir( $thisdir );
		}
	);
}

sub getextid {
	my ( $self, $ext ) = @_;
	$self->{extcache} = {} unless $self->{extcache};
	return Toolbox::Common::orcache(
		$self->{extcache},
		'ext', $ext,
		sub {
			my ( $thisext ) = @_;
			return $self->_findext( $ext );
		}
	);
}

sub _findext {
	my ( $self, $ext ) = @_;

	unless ( $self->{sths}->{findextsth} ) {
		$self->{sths}->{findextsth} = $self->{DBH}->prepare( "
			select id from ext_list where name = ? 
		" );
	}
	$self->{sths}->{findextsth}->execute( $ext );
	if ( my $row = $self->{sths}->{findextsth}->fetchrow_hashref() ) {
		return $row->{id};
	} else {
		my $storesth = $self->_storeextsth();
		$storesth->execute( $ext );
		return $self->getlastinsert();
	}
}

=head1 _*sth
	set or return misc statement handles

=cut

sub _storefilesth {
	my ( $self ) = @_;
	unless ( $self->{sths}->{storefilesth} ) {
		$self->{sths}->{storefilesth} = $self->{DBH}->prepare( "
			insert into file_list (name,dir_id,ext_id,size) values (?,?,?,?)
		" );
	}
	return $self->{sths}->{storefilesth};
}

sub checkifknown {
	my ( $self, $name, $dirid, $extid ) = @_;
	unless ( $self->{sths}->{checkfilesth} ) {
		$self->{sths}->{checkfilesth} = $self->{DBH}->prepare( "
			select * 
			from file_list 
			where name = ?
			and dir_id = ? 
			and ext_id = ?
	" );
	}
	$self->{sths}->{checkfilesth}->execute( $name, $dirid, $extid );
	if ( $self->{sths}->{checkfilesth}->fetchrow_hashref() ) {
		return 1;
	} else {
		return 0;
	}

}

sub _storedirsth {
	my ( $self ) = @_;
	unless ( $self->{sths}->{storedirsth} ) {
		$self->{sths}->{storedirsth} = $self->{DBH}->prepare( "
			insert into dir_list (name) values (?)
		" );
	}
	return $self->{sths}->{storedirsth};
}

sub _storeextsth {
	my ( $self ) = @_;
	unless ( $self->{sths}->{storeextsth} ) {
		$self->{sths}->{storeextsth} = $self->{DBH}->prepare( "
			insert into ext_list (name) values (?)
		" );
	}
	return $self->{sths}->{storeextsth};
}

sub getlastinsert {
	my ( $self ) = @_;
	unless ( $self->{sths}->{lastinsert} ) {
		$self->{sths}->{lastinsert} = $self->{DBH}->prepare( "
			select last_insert_rowid() as id
		" );
	}
	$self->{sths}->{lastinsert}->execute();
	if ( my $row = $self->{sths}->{lastinsert}->fetchrow_hashref() ) {
		return $row->{id};
	} else {
		return 0;
	}
}

=head1 get the dir_id for the file 
=head2 _finddir
	Retrieve directly
=cut

sub _finddir {
	my ( $self, $dir ) = @_;
	unless ( $self->{sths}->{finddirsth} ) {
		$self->{sths}->{finddirsth} = $self->{DBH}->prepare( "
			select id from dir_list where name = ? 
		" );
	}
	$self->{sths}->{finddirsth}->execute( $dir );
	if ( my $row = $self->{sths}->{finddirsth}->fetchrow_hashref() ) {
		return $row->{id};
	} else {
		my $storesth = $self->_storedirsth();
		$storesth->execute( $dir );
		return $self->getlastinsert();
	}
}

sub getfullpathforid {
	my ( $self, $id ) = @_;
	unless ( $self->{sths}->{getfullpathforid} ) {
		$self->{sths}->{getfullpathforid} = $self->{DBH}->prepare( "
				select 
					d.name as dir,
					f.name as file ,
					e.name as ext
				from 
					file_list f 
					join dir_list d 
						on f.dir_id = d.id
					join ext_list e 
						on f.ext_id = e.id
				where id = ? 
		" );
	}
	$self->{sths}->{getfullpathforid}->execute( $id );
	if ( my $row = $self->{sths}->{getfullpathforid}->fetchrow_hashref() ) {
		return "$row->{dir}/$row->{file}$row->{ext}";
	}
}

=head1 processing 

=cut

sub md5all {
	my ( $self ) = @_;
	my $fetchsth = $self->{DBH}->prepare( "
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
	$self->freshcommit();

}

sub md5path {
	my ( $self, $path ) = @_;

	#has been tested
	my $result = Toolbox::Common::md5binfile( $path );
	die $result->{fail} unless $result->{pass};
	return $result->{pass};
}

sub setidmd5 {
	my ( $self, $id, $md5 ) = @_;
	unless ( $self->{sths}->{setmd5} ) {
		$self->{sths}->{setmd5} = $self->{DBH}->prepare( "
				update file_list set md5 = ? where id = ?
		" );
	}
	$self->{sths}->{setmd5}->execute( $md5, $id );
	$self->commit();
}

sub initdirweight {
	my ( $self ) = @_;
	my $dirliststh = $self->{DBH}->prepare( "
				select * from dir_list order by name asc
		" );

	my $setweightsth = $self->{DBH}->prepare( "
				update dir_list set weight = ? where id = ?
		" );
	$dirliststh->execute();
	while ( my $row = $dirliststh->fetchrow_hashref() ) {
		my @slashes = split( $self->{dirsep}, $row->{name} );
		$setweightsth->execute( scalar( @slashes ), $row->{id} );
		$self->commit();
	}
	$self->freshcommit();
}

sub setonetrue {
	my ( $self ) = @_;
	my $md5ssth = $self->{DBH}->prepare(
		q/
		select distinct(md5) as md5 from file_list
	/
	);
	$md5ssth->execute();

	my $filesforsth = $self->{DBH}->prepare(
		q/
			select f.id
			from file_list f
			join dir_list d 
				on f.dir_id = d.id
			where md5 = ?
			order by d.weight desc , d.name desc , length(f.name) desc
	/
	);

	my $thisfilesth = $self->{DBH}->prepare(
		q/
		update file_list set one_true = 1 where id = ?
	/
	);

	my $thosefilesth = $self->{DBH}->prepare(
		q/
		update file_list set one_true_checked = 1 where md5 = ?
	/
	);
	while ( my $md5row = $md5ssth->fetchrow_hashref ) {
		print "md5row$/";
		$filesforsth->execute( $md5row->{md5} );
		my $onetruerow = $filesforsth->fetchrow_hashref();

		#this can't not be set unless the db was interfered with at some point
		print "Setting $onetruerow->{id} as one true $/";
		$thisfilesth->execute( $onetruerow->{id} );
		$thosefilesth->execute( $md5row->{md5} );
		$self->commit();
	}

	$self->freshcommit();
}

sub setcheckedanddelete {
	my ( $self ) = @_;
	my $truemd5sth = $self->{DBH}->prepare( "
		select md5, id from file_list where one_true = 1 and md5 is not null;
	" );

	my $checkedmd5sth = $self->{DBH}->prepare( "
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
		$self->commit();
	}
	$self->freshcommit();
}

sub dodeletes {
	my ( $self ) = @_;

	my $fetchsth = $self->{DBH}->prepare( "
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
	my $deletedsth = $self->{DBH}->prepare( "
			update file_list set deleted = 1 where id = ? ;
	" );
	$fetchsth->execute();
	while ( my $row = $fetchsth->fetchrow_hashref() ) {
		my $path = "$row->{dir}/$row->{file}$row->{ext}";
		if ( unlink( $path ) ) {

			print "deleted file [$path]$/" if $self->{debug} || $ENV{debug};
			$deletedsth->execute( $row->{id} );
			$self->commit();
		} else {
			warn "failed to delete file [$path]: $!";
		}
	}
	$self->freshcommit();
}

1;
