#!/usr/bin/perl
our $VERSION = 'v1.0.10';
##~ DIGEST : 8b08b838f8070755c2b033ed1899d207
# ABSTRACT : A script for gradually importing resources from a master mysql source to a slave source _without_ bringing the master out of production
use strict;
use warnings;

package Obj;
use Moo;
use parent 'Moo::GenericRoleClass::CLI';
use Time::HiRes;
use DBI;
use POSIX;
use Try::Tiny;
with qw/
  Moo::GenericRole::DB::MariaMysql
  Moo::GenericRole::DB
  Moo::GenericRole::JSON
  Moo::GenericRole::FileIO::CSV
  Moo::GenericRole::FileIO
  Moo::GenericRole::TimeHiRes
  Moo::GenericRole::NYTProf
  /;
ACCESSORS: {
	has source_db_conf => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return {} }
	);
	has target_db_conf => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return {} }
	);
	has source_dbh => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			my ( $self ) = @_;
			return $self->dbh_from_def( $self->source_db_conf() );
		}
	);
	has target_dbh => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			my ( $self ) = @_;
			return $self->dbh_from_def( $self->target_db_conf() );
		}
	);
	has replication_is_on => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			my $self       = shift;
			my $status_row = $self->get_slave_status();
			return $status_row->{Slave_IO_Running} && $status_row->{Slave_SQL_Running};
		}
	);
	has log_file_name => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return 'replicating_migrate_log_' . time . '.txt'; }
	);
	has log_pip_counter => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			return 0;
		}
	);
	has log_pip_limit => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			return 80;
		}
	);
	has get_source_auto_increment_sth => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			my ( $self ) = @_;
			return $self->source_dbh->prepare( qq|SELECT AUTO_INCREMENT FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? | ) or die $DBI::errstr;
		}
	);
}

sub process {

	my ( $self ) = @_;
	my $log_fh = $self->hot_ofh( $self->log_file_name() );
	$self->source_db_conf( $self->json_load_file( $self->cfg->{source_db_conf} ) );
	$self->target_db_conf( $self->json_load_file( $self->cfg->{target_db_conf} ) );
	my $table_stack = $self->single_csv_to_arref( $self->cfg->{table_csv} );
	my $table_configs;
	if ( $self->cfg->{table_configs} ) {
		$table_configs = $self->json_load_file( $self->cfg->{table_configs} );
	} else {
		$table_configs = {};
	}
	for my $table ( @{$table_stack} ) {
		print $log_fh "Working on $table at " . time . $/;
		$table_configs->{$table} ||= {};
		my $T = $table_configs->{$table};
		my ( $min, $max ) = ( 0, 0 );

		# TODO handle failed,restarted process
		if ( $T->{no_id} ) {
			die "no clue what to do here";
		} else {
			$self->source_dbh->do( "LOCK TABLES $table write" );
			$self->stop_replication();
			( $min, $max ) = $self->source_dbh->selectrow_array( "select min(id), max(id) from `$table`" ) or die $DBI::errstr;
			$self->transpose_autoincrement( $table );
			$self->source_dbh->do( "UNLOCK TABLES" );

			#for empty tables;
			$max ||= 0;

			# Now, we begin!
			unless ( $T->{no_truncate} ) {
				$self->target_dbh->do( "truncate `$table`" );
			}
			$T->{min} = $min;
			$T->{max} = $max;
			try {
				$self->floating_id_block_transfer( $table, $T );
			} catch {
				my $err_str = "Truncating failed table [$table]  : $_$/";
				print $log_fh $err_str;
				print $err_str;
				$self->target_dbh->do( "truncate `$table`" );
				$self->target_dbh->do( "CALL mysql.rds_stop_replication;" );
				$self->target_dbh->do( "CALL mysql.rds_start_replication;" );
			};
		}
		$self->start_replication();
		$self->wait_for_replication();
	}

}

sub wait_for_replication {

	my ( $self ) = @_;
	my $log_fh = $self->hot_ofh( $self->log_file_name() );
	$self->hot_ofh( $log_fh );
	print $log_fh "$/Waiting for replication to catch up.";
	print $log_fh $self->log_pip_reset();
	my $msg     = '';
	my $old_msg = '';
	LOOP: {
		while ( 1 ) {
			my $status = $self->get_slave_status();
			STATUS_CHECKS: {
				if ( $status->{Last_Errno} ) {
					$self->replication_broken( $status );
					last STATUS_CHECKS;
				}
				if ( $status->{Slave_SQL_Running} eq 'NO' ) {
					$msg = "Slave_SQL_Running = 'NO' - can't do anything.";
					warn $msg;
					last STATUS_CHECKS;
				}
				if ( $status->{Slave_IO_Running} eq 'NO' ) {
					$msg = "Slave_IO_Running = 'NO' - can't do anything.";
					warn $msg;
					last STATUS_CHECKS;
				}
				if ( defined( $status->{Seconds_Behind_Master} ) ) {
					if ( "$status->{Seconds_Behind_Master}" eq '0' ) {
						last LOOP;
					} else {
						$msg = "Seconds behind master: $status->{Seconds_Behind_Master}";
					}
				}
			}
			if ( $msg ne $old_msg ) {
				my $msg_string = $msg . $self->log_pip_reset();
				print $log_fh $msg_string;
			} else {
				my $pip = $self->log_pip();
				print $log_fh $pip;
			}
			sleep( 5 );
		}
	}
	my $final_msg = "$/Replication caught up - moving on.";
	print $log_fh $final_msg;
	print $final_msg;

}

=head3 replication_broken
	respond to broken replication - checking it actually is broken before doing anything 
=cut

sub replication_broken {
	my ( $self, $status ) = @_;
	$status ||= $self->get_slave_status();
	if ( $status->{Last_Errno} ) {
		my ( $truncate_table ) = ( $status->{Last_SQL_Error} =~ m|'INSERT INTO ([^(]+) \(| );
		if ( $truncate_table ) {
			$self->dbh->do( "TRUNCATE $truncate_table" );
			my $msg = "Auto truncated $truncate_table$/";

			$self->target_dbh->do( "CALL mysql.rds_start_replication;" );
			my $ofh = $self->hot_ofh( $self->log_file_name() );
			print $ofh $msg;
			warn $msg;
		} else {
			warn "Replication broken and cannot fix automatically";
		}
	}
}

sub stop_replication {

	my ( $self ) = @_;
	if ( $self->replication_is_on() ) {
		$self->target_dbh->do( $self->cfg->{stop_replication} || 'CALL mysql.rds_stop_replication' ) or die $DBI::errstr;
		$self->replication_is_on( 0 );
	}

}

sub start_replication {

	my ( $self ) = @_;
	unless ( $self->replication_is_on() ) {
		$self->target_dbh->do( $self->cfg->{start_replication} || 'CALL mysql.rds_start_replication' ) or die $DBI::errstr;
		$self->replication_is_on( 1 );
	}

}

sub get_slave_status {

	my ( $self ) = @_;
	return $self->target_dbh->selectrow_hashref( "SHOW SLAVE STATUS" );

}

=head3 floating_id_block_transfer
	From a great deal of parameters, transfer from source to target in gradually increasing increments until a specific time per activity is hit
=cut

sub floating_id_block_transfer {

	my ( $self, $table, $T ) = @_;
	die "no table(!?)" unless $table;
	my $log_fh      = $self->ofh( $self->log_file_name() );
	my $target_time = $self->cfg->{target_time} || 2;
	my $step        = 1;
	my $position    = $T->{min} || 0;
	my ( $start_string, $mid_string, $end_string ) = $self->mysqldump_string(
		{
			%{$self->source_db_conf}, table => $table,
		},
		[
			qw/
			  --compact
			  --no-create-info
			  --skip-comments
			  --skip-add-locks
			  --complete-insert
			  --hex-blob
			  --quick
			  --quote-names
			  --net_buffer_length=4096
			  /
		]
	);
	$self->stop_replication();
	my $old_step = 0;
	$self->timed_loop_sub(
		sub {
			my ( $faster ) = @_;

			# TODO finer grain calculations (?)
			if ( $faster ) {
				$step = ceil( $step * 1.1 );
			} else {

				#guess why this has to be ceil :D
				$step = ceil( $step * 0.8 );
			}

			# TODO something really really clever here to get the optimal export value
			if ( $step >= 20000 ) {
				$step = 20000;
			}
			if ( $step != $old_step ) {
				print $log_fh "Changing step to $step";
				print $log_fh $self->log_pip_reset();
			} else {
				print $log_fh $self->log_pip();
			}
			$old_step = $step;

			#the explicit bounding here is required to support the pending statements when replication comes on again
			my $next_bound = $position + $step;

			#go right to the limit of what was present at the start of de-replication
			my $maxed = 0;
			if ( $next_bound > $T->{max} ) {
				$next_bound = $T->{max};
				$maxed      = 1;
			}

			#create the mysqldump string
			my $cstring = qq|$start_string $mid_string --where="id >= $position and id <= $next_bound" $end_string|;

			#step to the bottom of the next bound
			$position = $next_bound + 1;

			#from mysql dump, create the insert statements
			my $res = `$cstring`;
			if ( $res ) {

				#for each statement which contains 1-n rows limited by the net_buffer_length value and $/ delimited, perform the insert
				for my $sub_res ( split( $/, $res ) ) {
					$self->target_dbh->do( $sub_res ) or die $DBI::errstr;
				}

				#done
				if ( $maxed ) {
					return 0;
				}

				#potentially more
				return 1;
			}
		},
		$target_time
	);
	$self->start_replication();

}

=head3 single_csv_to_arref

	turn $column from a csv into an array

=cut

sub single_csv_to_arref {

	my ( $self, $source, $c ) = @_;
	$c ||= {};
	my @return;
	my $column = $c->{column} || 0;
	$self->sub_on_csv(
		sub {
			my $row = shift;
			push( @return, $row->[$column] ) if $row->[$column];
		},
		$source
	);
	return \@return; #return!

}

sub _set_dbh {

	my $self = shift;
	return $self->dbh_from_def( $self->cfg->{source_db_conf} );

}

sub log_pip {

	my ( $self ) = @_;
	if ( $self->log_pip_counter >= $self->log_pip_limit ) {
		return $self->log_pip_reset();
	}
	$self->log_pip_counter( $self->log_pip_counter + 1 );
	return '.';

}

sub log_pip_reset {

	my ( $self ) = @_;
	$self->log_pip_counter( 1 );
	return $/;

}

sub transpose_autoincrement {

	my ( $self, $table ) = @_;
	die "Table not provided" unless $table;

	#TODO write lock on target when getting id
	#set explicit target id
	my $db = $self->source_db_conf->{database};
	$self->get_source_auto_increment_sth->execute( $db, $table ) or die $DBI::errstr;
	my ( $auto_increment ) = $self->get_source_auto_increment_sth->fetchrow_array() || 0;
	$auto_increment ||= 0;
	$self->target_dbh->do( "ALTER TABLE  `$table` AUTO_INCREMENT = $auto_increment" );
	warn "set $table to $auto_increment AUTO_INCREMENT";

}
1;

package main;
main();

sub main {

	my $self = Obj->new();
	select( STDERR );
	$| = 1;
	select( STDOUT ); # default
	$| = 1;
	$self->get_config(
		[qw/ source_db_conf target_db_conf table_csv /],
		[qw/ nytprofile /],
		{
			required => {
				source_db_conf => 'Source database connection details in json format',
				target_db_conf => 'Target database connection details in json format',
				table_csv      => 'CSV file with list of tables to process',
			},
			flags => [qw/ nytprofile /]
		}
	);
	$self->start_nyt_profile() if $self->{cfg}->{nytprofile};
	$self->process();
	$self->finish_nyt_profile() if $self->{cfg}->{nytprofile};

}
