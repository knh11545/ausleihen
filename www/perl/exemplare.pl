#!/usr/bin/perl -w -t

=head1 NAME
  
  exemplare.pl
  
=head1 DESCRIPTION
  
  Show data about books retrieved from SISIS. Should be rum from a web server as a CGI script.

  You need to edit this script to configure it.
  
=cut  


use strict;
use utf8;
use DBI;
use DBD::Sybase;
use CGI;

my $DB = "database";
my $port = 4321;
my $host = "fully.qualified.hostname";
my $conn = "dbi:Sybase:server=$host:$port;database=$DB;timeout=10";
my $user = "user";
my $password = "password";
my $dbh;
my $sth;
my $query = "";
#$query = "select \@\@servername";
my $library_name = "Name der Bibliothek";
my $firefox_plugin = "./../exemplardatensuche.xml"; # path to Firefox search plugin on web server


#####################################################################################################
# Any configuration should be done above
#####################################################################################################


my $cgi = CGI::new();
print $cgi->header(
	-charset=>'UTF-8',
);
print $cgi->start_html( 
		-title    => 'Exemplardaten',
		-encoding => 'UTF-8',
		-head     => [
			$cgi->Link( { 
				-rel   => 'search',  
				-type  => 'application/opensearchdescription+xml',
				-title => 'Suche nach Exemplardaten',
				-href  => $firefox_plugin,
			} ),
		],	
	);

print '<div style="right:0; position:absolute; padding-right:1em">'.$library_name.'</div>';
my @katkeys = $cgi->param( 'katkey' );
my $katkey_is_set = scalar @katkeys;
my @shelfmarks = $cgi->param( 'shelfmark' );
my $shelfmark_is_set = scalar @shelfmarks;

print $cgi->start_form(-method=>'GET'),
	"katkey ", $cgi->textfield(-name=>'katkey', -size=>20,), " oder ",
	"Signatur ", $cgi->textfield(-name=>'shelfmark', -size=>20,),
	$cgi->submit(-name=>'Suchen'),
	$cgi->endform(),
	$cgi->hr();

unless ( $katkey_is_set || $shelfmark_is_set )
{
	 print "Need to supply katkey or shelfmark!\n",
	 		$cgi->end_html();
	 exit;
}

# Connect to database.
$dbh = DBI->connect( $conn, $user, $password )
    or die "Can't connect to database $conn: $DBI::errstr\n";

# Check query parameters.
my $katkey = $katkeys[0];

if ( $katkey )
{
	$katkey =~ s/^\s+//;
	$katkey =~ s/\s+$//;
	unless ( $katkey =~ m/^\d+$/ )
	{
		 print "\"$katkey\" is not a valid katkey!\n",
				$cgi->end_html();
		 exit;
	}
}
else
{
	my $shelfmark = $shelfmarks[0];
	$shelfmark =~ s/^\s+//;
	$shelfmark =~ s/\s+$//;
	unless ( $shelfmark )
	{
		 print "Need to supply katkey or shelfmark!\n",
				$cgi->end_html();
		 exit;
	}
	else
	{
		my $query = "
			SELECT
				titel_buch_key.katkey AS katkey
			FROM
				ubrsis.sisis.titel_buch_key titel_buch_key, ubrsis.sisis.d01buch d01buch
			WHERE
				titel_buch_key.mcopyno = d01buch.d01mcopyno
				AND titel_buch_key.seqnr = 1
				AND d01buch.d01ort = '$shelfmark'
			";
		$sth = $dbh->prepare( $query );
		if($sth->execute)
		{
			while ( my $row = $sth->fetchrow_hashref )
			{
				$katkey = $row->{katkey};
			}
			unless ( $katkey )
			{
				 print "No katkey found. Check shelfmark!\n",
					$cgi->end_html();
		 		exit;
			}
		}
	}
}

# Titeldaten
print "<h1>Exemplardaten aus dem Lokalsystem</h1>\n";
$query = "
		SELECT 
			titel_dupdaten.autor_avs
			, titel_dupdaten.titel_avs
			, titel_dupdaten.zusatz
			, titel_dupdaten.verlag
			, titel_dupdaten.erschjahr
			, titel_dupdaten.isbn
		FROM 
			ubrsis.sisis.titel_dupdaten titel_dupdaten 
		WHERE 
			titel_dupdaten.katkey = $katkey
		";
#print "Query:\n  $query\n\n";
$sth = $dbh->prepare( $query );
if($sth->execute) {
	#my $cols = $sth->{NAME};
	print "<p>\n";
	while ( my $row = $sth->fetchrow_hashref )
	{
		print "Autor: $row->{autor_avs}<br />\n";
		print "Titel: $row->{titel_avs}. $row->{zusatz}<br />\n";
		print "Erscheinungsjahr: $row->{erschjahr}<br />\n";
		print "Verlag: $row->{verlag}<br />\n";
		print "ISBN: $row->{isbn}<br />\n";
		print "katkey: $katkey<br />\n";
	}
	print "</p>\n";

}

# In the following query we add a day to the date difference between today and d01buch.d01aufnahme to avoid divisions by zero.
# There is no need to be too accurate in these numbers. The book is not available to users on that day anyway.
$query = "
		SELECT 
			d01buch.d01ort AS 'Signatur'
			, ROUND( d01buch.d01savanz / ( ( 1.0 + datediff(day, d01buch.d01aufnahme, getdate()) ) / 360 ), 2 ) AS 'Ausleihen pro Jahr'
			, d01buch.d01savanz AS 'Ausleihen gesamt'
			, d01buch.d01sljanz AS 'Ausleihen lfd. Jahr'
			, d01buch.d01svjanz AS 'Ausleihen Vorjahr'
			, d01buch.d01svvjanz AS 'Ausleihen Vorvorjahr'
			, d01buch.d01svmanz AS 'Vormerkungen gesamt'
			, d01buch.d01vmanz AS 'Vormerkungen aktuell'
			, CONVERT( char(10), d01buch.d01aufnahme, 104) AS 'Datum Medienaufnahme'
			, d01buch.d01status AS 'Ausleih- status'
			, d01buch.d01bg AS 'Benutzer- gruppe'
			, d02ben.d02fakul AS 'Fakultät'
			, CONVERT( char(10), d01buch.d01lrv1, 104) AS 'Datum letzte Rückgabe'
			, d01buch.d01entl AS 'Entleih- barkeit'
			, d01buch.d01mtyp AS 'Medientyp'
		FROM 
			ubrsis.sisis.d01buch d01buch
			INNER JOIN ubrsis.sisis.titel_buch_key titel_buch_key
				ON ( (titel_buch_key.mcopyno = d01buch.d01mcopyno) AND (titel_buch_key.seqnr = 1) )
			LEFT OUTER JOIN ubrsis.sisis.d02ben d02ben
				ON ( d01buch.d01bnr = d02ben.d02bnr )
		WHERE 
			titel_buch_key.katkey  = $katkey
		ORDER BY
			d01buch.d01ort
		";


$sth = $dbh->prepare( $query );
if($sth->execute) {

	print mysql_result2xhtml_table( $sth );
	
}


print $cgi->end_html();
exit();


# Make an XHTML table from query result
sub mysql_result2xhtml_table
{
	my $sth = shift;
	my $cols = $sth->{NAME};

	my $table = "<table border=\"1\">\n";
	$table .= "  <thead>\n";
	$table .= "  <tr>\n";
	foreach my $mycol ( @$cols )
	{
		$table .= "    <th>$mycol</th>\n";
	}
	$table .= "  </tr>\n";
	$table .= "  </thead>\n";

	$table .= "  <tbody>\n";
	while ( my $row = $sth->fetchrow_arrayref )
	{
		$table .= "    <tr>\n";
		foreach my $value ( @$row )
		{
			$value = "" unless defined $value; # take care of NULL values from query result
			$table .= "      <td>$value</td>\n";
		}
		$table .= "    </tr>\n";
	}
	$table .= "  </tbody>\n";
	$table .= "<table>\n";
	return $table;
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

