#!/usr/bin/perl -w

=head1 NAME
  
  get_loan_statistics.pl
  
=head1 DESCRIPTION
  
  Retrieve loan statistics from catalogue database and write them to a MySQL database for logging.

  You need to edit this script to configure it.
  
=cut  

use strict;
use utf8;
use DBI;
use DBD::Sybase;
use Data::Dumper;

my $DEBUG = 2;

# DBI parameters: catalogue
my $DB = "sisis";
my $port = 4321;
my $host = "fully.qualified.hostname";
my $conn = "dbi:Sybase:server=$host:$port;database=$DB;timeout=300";	# timeout: wait up to 5 minutes
my $user = "username";
my $password = "password";
my $sth;
my $query = "";
my @shelfmark_patterns = ('9117/%', '9118/%', '17/%', '1701/%'); # For every book/copy retrieved by this shelfmark pattern an entry of the loan status is saved. This will usually only make sense for textbooks.

# DBI parameters: database for statistics logging
my $stat_db = "bestand";
my $stat_dbhost = "localhost";
my $stat_conn = "dbi:mysql:$stat_db:$stat_dbhost";
my $stat_user = "username";
my $stat_password = "password";
my $stat_sth;
my $insert_query;
my $TABLE_LOAN_STATISTICS = "loan_statistics";
my $TABLE_LOAN_STATUS = "loan_status";

# The following parameters should be set to 0 unless heavy debugging is done!!!
my $SKIP_LOAN_STATISTICS = 0;
my $SKIP_LOAN_STATUS = 0;

#####################################################################################################
# Any configuration should be done above
#####################################################################################################

# Conect to catalog.
my $dbh = DBI->connect( $conn, $user, $password )
    or die "Can't connect to database $conn: $DBI::errstr\n";

# Connect to logging database
my $stat_dbh = DBI->connect( $stat_conn, $stat_user, $stat_password )
    or die "Can't connect to database $stat_conn: $DBI::errstr\n";
$stat_dbh->{RaiseError} = 1;
	
# Get shelfmark patterns for which to retrieve statistics.
my %shelfmarks = get_shelfmarks_with_branch_id( $stat_dbh );

# Map loan status codes to table column names in logging database
my %loan_status_codes = (
		0 => 'free',
		2 => 'ordered',
		4 => 'borrowed',
		8 => 'sent_back',
		);

# Process shelfmarks
unless ( $SKIP_LOAN_STATISTICS ) 
{
	foreach my $shelfmark ( sort keys %shelfmarks )
	{

		# Total number of books
		my $total = get_total_number_of_books( $dbh, $shelfmark );
		print "\nshelfmark: $shelfmark\n" if ( $DEBUG > 0 );
		print "\ttotal: $total books\n" if ( $DEBUG > 0 );

		# Query to retrieve loan statistics
		# Sybase: dynamic SQL (? placeholders) are not supported by the server
		$query = "
				SELECT 
					d01status AS loan_status
					, Count(SYB_IDENTITY_COL) AS number_books
				FROM 
					ubrsis.sisis.d01buch
				WHERE 
					d01ort LIKE \"$shelfmark\"
				GROUP BY 
					d01status
				";
		print "$query\n" if ( $DEBUG > 1 );
		$sth = $dbh->prepare( $query );


		# Query to insert statistics into logging database
		$insert_query = "
				REPLACE INTO $TABLE_LOAN_STATISTICS
				SET
					shelfmark = '$shelfmark',
					branch_id = $shelfmarks{$shelfmark},
					total = $total
				";

		unless ( $sth->execute() )
		{
			print "An Error occured while trying to execute query\n$query\n";
			die "ERROR: $sth->errstr\n"
		};

		while ( my $row = $sth->fetchrow_hashref ) {
			print 	"\t$loan_status_codes{$row->{'loan_status'}}\t", "$row->{'number_books'} books\t(", sprintf( "%.2f", $row->{'number_books'}*100/$total), "%)\n" if ( $DEBUG > 0 );
			$insert_query .= ", $loan_status_codes{$row->{'loan_status'}}=$row->{'number_books'}";
			
		}

		$insert_query .= ", date = CURRENT_DATE()";
		print "$insert_query\n" if ( $DEBUG > 1 );
		$stat_sth = $stat_dbh->prepare( $insert_query );
		unless ($stat_sth->execute)
		{
			print "An Error occured while trying to execute query\n$$insert_query\n";
			die "ERROR: $stat_sth->errstr\n"
		};

	}
}

unless ( $SKIP_LOAN_STATUS ) 
{
	foreach my $shelfmark ( @shelfmark_patterns )
	{
		$query = "
			SELECT 
				d01buch.d01titlecatkey,
				d01buch.d01gsi,
				d01buch.d01ort,
				d01buch.d01ex,
				d01buch.d01status,
				CONVERT(VARCHAR, d01buch.d01av, 112) AS d01av,
				CONVERT(VARCHAR, d01buch.d01rv, 112) AS d01rv,
				d01buch.d01vlanz,
				d01buch.d01bg,
				d01buch.d01vmanz,
				d02ben.d02fakul
			FROM 
				ubrsis.sisis.d01buch d01buch 
				LEFT OUTER JOIN ubrsis.sisis.d02ben d02ben
					ON ( d01buch.d01bnr = d02ben.d02bnr )
			WHERE 
				d01buch.d01ort LIKE \"$shelfmark\"
		";

		print "$query\n" if ( $DEBUG > 1 );
		$sth = $dbh->prepare( $query );
		unless ( $sth->execute() )
		{
			print "An Error occured while trying to execute query\n$query\n";
			die "ERROR: $sth->errstr\n"
		};

		# Query to insert statistics into logging database
		my $insert_query = "
				REPLACE INTO $TABLE_LOAN_STATUS
				SET 
					d01katkey	= ?,
					d01gsi		= ?,
					d01ort		= ?,
					d01status	= ?,
					d01av		= DATE(?),
					d01rv		= DATE(?),
					d01vlanz	= ?,
					d01bg		= ?,
					d01vmanz	= ?,
					d02fakul	= ?,
					date =  CURRENT_DATE()
		";
		$stat_sth = $stat_dbh->prepare( $insert_query );

		while ( my $row = $sth->fetchrow_hashref ) 
		{

			print "SISIS: ", Dumper($row) if ( $DEBUG > 1 );
			my $d02fakul = defined $row->{'d02fakul'} ? $row->{'d02fakul'} : "NULL";
			$stat_sth->bind_param( 1,  $row->{'d01titlecatkey'}    );
			$stat_sth->bind_param( 2,  $row->{'d01gsi'}    );
			$stat_sth->bind_param( 3,  $row->{'d01ort'}    );
			$stat_sth->bind_param( 4,  $row->{'d01status'} );
			$stat_sth->bind_param( 5,  $row->{'d01av'}     );
			$stat_sth->bind_param( 6,  $row->{'d01rv'}     );
			$stat_sth->bind_param( 7,  $row->{'d01vlanz'}  );
			$stat_sth->bind_param( 8,  $row->{'d01bg'}     );
			$stat_sth->bind_param( 9,  $row->{'d01vmanz'}  );
			$stat_sth->bind_param( 10, $d02fakul           );
			unless ($stat_sth->execute)
			{
				print "An Error occured while trying to execute query\n$insert_query\n";
				die "ERROR $stat_sth->err: $stat_sth->errstr\n"
			};
		}
	}
}



# Konvertierung der datetime-Angaben aus Sybase nach MySQL-Datumsformat; die Sybase-Funktionen datepart, datename und convert funktionieren nicht wie in der Doku beschrieben: 
# select DATE( STR_TO_DATE( 'Mon Jul 30 01:02:03 2007', '%a %b %d %H:%i:%s %Y' ) );
# Bekannter Fehler: Das Ausgabeformat ist locale-abhängig. Bei LANG=POSIX funktioniert es.
#
# 02.10.2012: mit CONVERT(VARCHAR, d01buch.d01av, 112) funktioniert es: YYYYMMDD (ISO), was MySQL ohne weiteres als DATE parst.


=head2 Functions

=over 2

=item my @shelfmarks = get_shelfmarks( $dbh  );

Get shelfmark patterns from logging database.

=back 

=cut

sub  get_shelfmarks_with_branch_id
{
	my $dbh = shift;
	die "No database handle given to get_shelfmarks()" unless $dbh;
	
	my %shelfmarks;
	my $query = "SELECT shelfmark, branch_id FROM locations;";
	my $sth = $dbh->prepare( $query );
	unless ($sth->execute)
	{
		print "An Error occured while trying to execute query\n$query\n";
		die "ERROR: $sth->errstr\n";
	}

	while ( my @row = $sth->fetchrow_array ) 
	{
		$shelfmarks{$row[0]} = $row[1];
	}
	return %shelfmarks;
}

=over 2

=item my $total = get_total_number_of_books( $dbh, $shelfmark  );

Retrieve total number of books for shelfmark pattern from catalogue.

=back 

=cut


sub get_total_number_of_books
{
	my $dbh = shift;
	die "No database handle given to get_total_number_of_books()" unless $dbh;
	my $shelfmark = shift;
	die "No shelfmark given to get_total_number_of_books()" unless $shelfmark;

	my $query = "
			SELECT 
				COUNT(d01buch.SYB_IDENTITY_COL) AS total
			FROM 
				ubrsis.sisis.d01buch d01buch
			WHERE 
				d01buch.d01ort Like \"$shelfmark\"
			";
	print "$query\n" if ( $DEBUG > 1 );

	my $sth = $dbh->prepare( $query );
	unless ($sth->execute)
	{
		print "An Error occured while trying to execute query\n$query\n";
		die "ERROR: $sth->errstr\n";
	}

	my $total;
	while ( my $row = $sth->fetchrow_hashref ) {
		$total = $row->{'total'};
	}
	return $total;

}

=head1 AUTHORS


  Author: Helge Knüttel
  
=head1 COPYRIGHT 

  Copyright (C) 2007-2013 Helge Knüttel.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

=cut
